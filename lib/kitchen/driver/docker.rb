# -*- encoding: utf-8 -*-
#
# Copyright (C) 2013, Sean Porter
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen'
require 'json'
require 'docker'

module Kitchen

  module Driver

    # Docker driver for Kitchen.
    #
    # @author Sean Porter <portertech@gmail.com>
    class Docker < Kitchen::Driver::SSHBase

      default_config :socket,        nil
      default_config :privileged,    false
      default_config :remove_images, false
      default_config :run_command,   '/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no'
      default_config :username,      'kitchen'
      default_config :password,      'kitchen'
      default_config :ruby_client,          false
      default_config :read_timeout,         300

      default_config :use_sudo do |driver|
        !driver.remote_socket?
      end

      default_config :image do |driver|
        driver.default_image
      end

      default_config :platform do |driver|
        driver.default_platform
      end

      def verify_dependencies
        if config[:ruby_client]
          ::Docker.url = config[:socket] if config[:socket]
          ::Docker.options = {
            :read_timeout => config[:read_timeout]
          }
          unless ::Docker.validate_version!
            raise UserError,
            'The ruby client is incompatible with your Docker server'
          end
        else
          begin
            run_command('docker > /dev/null', :quiet => true)
          rescue
            raise UserError,
            'You must first install Docker http://www.docker.io/gettingstarted/'
          end
        end
      end

      def default_image
        platform, release = instance.platform.name.split('-')
        release ? [platform, release].join(':') : 'base'
      end

      def default_platform
        instance.platform.name.split('-').first || 'ubuntu'
      end

      def create(state)
        debug("State (create): #{state.inspect}")
        debug("Config (create): #{config.inspect}")

        state[:image_id] = build_image(state) unless state[:image_id]
        state[:container_id] = run_container(state) unless state[:container_id]
        state[:hostname] = remote_socket? ? socket_uri.host : 'localhost'
        state[:port] = container_ssh_port(state)
        wait_for_sshd(state[:hostname], nil, :port => state[:port])
      end

      def destroy(state)
        rm_container(state) if state[:container_id]
        if config[:remove_images] && state[:image_id]
          rm_image(state)
        end
      end

      def remote_socket?
        config[:socket] ? socket_uri.scheme == 'tcp' : false
      end

      protected

      def socket_uri
        URI.parse(config[:socket])
      end

      def docker_command(cmd, options={})
        docker = "docker"
        docker << " -H #{config[:socket]}" if config[:socket]
        run_command("#{docker} #{cmd}", options)
      end

      def dockerfile
        from = "FROM #{config[:image]}"
        platform = case config[:platform]
        when 'debian', 'ubuntu'
          <<-eos
            ENV DEBIAN_FRONTEND noninteractive
            RUN dpkg-divert --local --rename --add /sbin/initctl
            RUN ln -sf /bin/true /sbin/initctl
            RUN apt-get update
            RUN apt-get install -y sudo openssh-server curl lsb-release
          eos
        when 'rhel', 'centos'
          <<-eos
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients curl
            RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
            RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
          eos
        else
          raise ActionFailed,
          "Unknown platform '#{config[:platform]}'"
        end
        username = config[:username]
        password = config[:password]
        base = <<-eos
          RUN mkdir -p /var/run/sshd
          RUN useradd -d /home/#{username} -m -s /bin/bash #{username}
          RUN echo #{username}:#{password} | chpasswd
          RUN echo '#{username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        eos
        custom = ''
        Array(config[:provision_command]).each do |cmd|
          custom << "RUN #{cmd}\n"
        end
        [from, platform, base, custom].join("\n")
      end

      def parse_image_id(output)
        output.each_line do |line|
          if line =~ /image id|build successful|successfully built/i
            return line.split(/\s+/).last
          end
        end
        raise ActionFailed,
        'Could not parse Docker build output for image ID'
      end

      def build_image(state)
        if config[:ruby_client]
          debug("Dockerfile (build_image):\n#{dockerfile}")
          ::Docker::Image.build(dockerfile).id
        else
          output = docker_command("build -", :input => dockerfile)
          parse_image_id(output)
        end
      end

      def get_container_by_id(state)
        ::Docker::Container.all(:all => true).select { |c|
          /#{state[:container_id]}/ =~ c.id
        }.first
      end

      def get_image_by_id(state)
        ::Docker::Image.all(:all => true).select { |i|
          /#{state[:image_id]}/ =~ i.id
        }.first
      end

      def parse_container_id(output)
        container_id = output.chomp
        unless [12, 64].include?(container_id.size)
          raise ActionFailed,
          'Could not parse Docker run output for container ID'
        end
        container_id
      end

      def build_run_command(image_id)
        cmd = "run -d -p 22"
        Array(config[:forward]).each {|port| cmd << " -p #{port}"}
        Array(config[:dns]).each {|dns| cmd << " -dns #{dns}"}
        Array(config[:volume]).each {|volume| cmd << " -v #{volume}"}
        cmd << " -h #{config[:hostname]}" if config[:hostname]
        cmd << " -m #{config[:memory]}" if config[:memory]
        cmd << " -c #{config[:cpu]}" if config[:cpu]
        cmd << " -privileged" if config[:privileged]
        cmd << " #{image_id} #{config[:run_command]}"
        cmd
      end

      def container_config(state)
        conf_hash = {
          Cmd: ['/usr/sbin/sshd','-D','-o UseDNS=no','-o UsePAM=no'],
          Image: state[:image_id],
          Volumes: {},
          AttachStdout: true,
          AttachStderr: true,
          PortBindings: {},
          Privileged: config[:privileged],
          PublishAllPorts: false
        }

        exposed_ports = []
        exposed_ports << '22'
        Array(config[:forward]).each { |port| exposed_ports << port.to_s }
        Array(exposed_ports).each do |port|
          if port.to_s.include? ':'
            (hostport, guestport) = port.split(':')
          else
            hostport = ''
            guestport = port.to_s
          end
          conf_hash[:PortBindings] ["#{guestport}/tcp"] = [{
              HostIp: '',
              HostPort: hostport
          }]
        end
        conf_hash[:PortSpecs] = exposed_ports

        conf_hash[:Dns] = config[:dns] if config[:dns]
        Array(config[:volume]).each { |volume| conf_hash[:Volumes]["#{volume}"] = {} }
        conf_hash[:Memory] = config[:memory] if config[:memory]
        conf_hash[:CpuShares] = config[:cpu] if config[:cpu]
        conf_hash[:Hostname] = config[:hostname] if config[:hostname]
        debug("Container Config (container_config):\n#{conf_hash}")

        conf_hash
      end

      def run_container(state)
        if config[:ruby_client]
          c_config = container_config(state)
          container = ::Docker::Container.create(c_config)
          debug("Container (run_container) Created: #{container.json.inspect}")
          state[:container_id] = container.id
          container.start(c_config)
          debug("Container (run_container) Started: #{container.json.inspect}")
          container.id
        else
          cmd = build_run_command(state[:image_id])
          output = docker_command(cmd)
          parse_container_id(output)
        end
      end

      def parse_container_ssh_port(output)
        begin
          info = Array(::JSON.parse(output)).first
          ports = info['NetworkSettings']['Ports']
          ssh_port = ports['22/tcp'].detect {|port| port['HostIp'] == '0.0.0.0'}
          ssh_port['HostPort'].to_i
        rescue
          raise ActionFailed,
          'Could not parse Docker inspect output for container SSH port'
        end
      end

      def container_ssh_port(state)
        if config[:ruby_client]
          container = get_container_by_id(state)
          container.json['NetworkSettings']['Ports']['22/tcp'].first['HostPort']
        else
          output = docker_command("inspect #{state[:container_id]}")
          parse_container_ssh_port(output)
        end
      end

      def rm_container(state)
        if config[:ruby_client]
          get_container_by_id(state).stop
          get_container_by_id(state).delete
        else
          container_id = state[:container_id]
          docker_command("stop #{container_id}")
          docker_command("rm #{container_id}")
        end
      end

      def rm_image(state)
        if config[:ruby_client]
          get_image_by_id(state).remove
        else
          docker_command("rmi #{state[:image_id]}")
        end
      end
    end
  end
end
