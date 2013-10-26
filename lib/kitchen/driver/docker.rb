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

module Kitchen

  module Driver

    # Docker driver for Kitchen.
    #
    # @author Sean Porter <portertech@gmail.com>
    class Docker < Kitchen::Driver::SSHBase

      default_config :port,                 '22'
      default_config :username,             'kitchen'
      default_config :password,             'kitchen'
      default_config :require_chef_omnibus, true
      default_config :remove_images,        false
      default_config :use_sudo,             true
      default_config :image do |driver|
        driver.default_image
      end
      default_config :platform do |driver|
        driver.default_platform
      end

      def verify_dependencies
        run_command('docker > /dev/null', :quiet => true)
        rescue
          raise UserError,
          'You must first install Docker http://www.docker.io/gettingstarted/'
      end

      def default_image
        platform, release = instance.platform.name.split('-')
        release ? [platform, release].join(':') : 'base'
      end

      def default_platform
        instance.platform.name.split('-').first || 'ubuntu'
      end

      def create(state)
        state[:image_id] = build_image(state) unless state[:image_id]
        state[:container_id] = run_container(state) unless state[:container_id]
        state[:hostname] = container_address(state) unless state[:hostname]
        wait_for_sshd(state[:hostname])
      end

      def destroy(state)
        rm_container(state) if state[:container_id]
        if config[:remove_images] && state[:image_id]
          rm_image(state)
        end
      end

      protected

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
        output = run_command("docker build -", :input => dockerfile)
        parse_image_id(output)
      end

      def parse_container_id(output)
        container_id = output.chomp
        unless container_id.size == 12
          raise ActionFailed,
          'Could not parse Docker run output for container ID'
        end
        container_id
      end

      def build_run_command(image_id)
        cmd = 'docker run -d'
        Array(config[:forward]).each {|port| cmd << " -p #{port}"}
        Array(config[:dns]).each {|dns| cmd << " -dns #{dns}"}
        Array(config[:volume]).each {|volume| cmd << " -v #{volume}"}
        cmd << " -m #{config[:memory]}" if config[:memory]
        cmd << " -c #{config[:cpu]}" if config[:cpu]
        cmd << " #{image_id} /usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no"
        cmd
      end

      def run_container(state)
        cmd = build_run_command(state[:image_id])
        output = run_command(cmd)
        parse_container_id(output)
      end

      def parse_container_ip(output)
        begin
          info = Array(::JSON.parse(output)).first
          settings = info['NetworkSettings']
          settings['IpAddress'] || settings['IPAddress']
        rescue
          raise ActionFailed,
          'Could not parse Docker inspect output for container IP address'
        end
      end

      def container_address(state)
        container_id = state[:container_id]
        output = run_command("docker inspect #{container_id}")
        parse_container_ip(output)
      end

      def rm_container(state)
        container_id = state[:container_id]
        run_command("docker stop #{container_id}")
        run_command("docker rm #{container_id}")
      end

      def rm_image(state)
        image_id = state[:image_id]
        run_command("docker rmi #{image_id}")
      end
    end
  end
end
