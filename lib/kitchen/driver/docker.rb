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
        ::Docker.url = config[:socket] if config[:socket]
        ::Docker.options = {
          :read_timeout => config[:read_timeout]
        }
        unless ::Docker.validate_version!
          raise UserError,
          'The ruby client is incompatible with your Docker server'
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

      def build_image(state)
        debug("Dockerfile (build_image):\n#{dockerfile}")
        ::Docker::Image.build(dockerfile).id
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

      def container_config(state)
        conf_hash = {
          Cmd: config[:run_command].split,
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
        c_config = container_config(state)
        container = ::Docker::Container.create(c_config)
        debug("Container (run_container) Created: #{container.json.inspect}")
        state[:container_id] = container.id
        container.start(c_config)
        debug("Container (run_container) Started: #{container.json.inspect}")
        container.id
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
        container = get_container_by_id(state)
        container.json['NetworkSettings']['Ports']['22/tcp'].first['HostPort']
      end

      def rm_container(state)
        get_container_by_id(state).stop
        get_container_by_id(state).delete
      end

      def rm_image(state)
        get_image_by_id(state).remove
      end
    end
  end
end
