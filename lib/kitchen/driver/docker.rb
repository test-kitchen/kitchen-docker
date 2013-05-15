# -*- encoding: utf-8 -*-
#
# Author:: Sean Porter (<portertech@gmail.com>)
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

module Kitchen

  module Driver

    # Docker driver for Kitchen.
    #
    # @author Sean Porter <portertech@gmail.com>
    class Docker < Kitchen::Driver::SSHBase

      default_config :image,                'ubuntu'
      default_config :platform,             'ubuntu'
      default_config :port,                 '22'
      default_config :username,             'kitchen'
      default_config :password,             'kitchen'
      default_config :require_chef_omnibus, true

      def verify_dependencies
        run_command('docker > /dev/null', :quiet => true)
        rescue
          raise UserError,
          'You must first install Docker http://www.docker.io/gettingstarted/'
      end

      def create(state)
        state[:image_id] = build_image(state) unless state[:image_id]
        state[:container_id] = run_container(state) unless state[:container_id]
        state[:hostname] = container_address(state) unless state[:hostname]
        wait_for_sshd(state[:hostname])
        ensure_fqdn(state)
      end

      def destroy(state)
        kill_container(state) if state[:container_id]
        rm_image(state) if state[:image_id]
      end

      protected

      def dockerfile
        from = "FROM #{config[:image]}"
        platform = case config[:platform]
        when 'debian', 'ubuntu'
          <<-eos
            ENV DEBIAN_FRONTEND noninteractive
            RUN apt-get update
            RUN apt-get install -y sudo openssh-server
          eos
        when 'rhel', 'centos'
          <<-eos
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients
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
          RUN mkdir /var/run/sshd
          RUN echo '127.0.0.1 localhost.localdomain localhost' >> /etc/hosts
          RUN useradd -d /home/#{username} -m -s /bin/bash #{username}
          RUN echo #{username}:#{password} | chpasswd
          RUN echo '#{username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        eos
        [from, platform, base].join("\n")
      end

      def parse_image_id(output)
        output.each_line do |line|
          return line.split(/\s+/).last if line =~ /image id/i
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

      def run_container(state)
        image_id = state[:image_id]
        cmd = "docker run -d #{image_id} /usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no"
        output = run_command(cmd)
        parse_container_id(output)
      end

      def parse_container_ip(output)
        begin
          info = JSON.parse(output)
          info['NetworkSettings']['IpAddress']
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

      def ensure_fqdn(state)
        ssh_args = build_ssh_args(state)
        ssh(ssh_args, 'echo "127.0.0.1 `hostname`" | sudo tee -a /etc/hosts')
      end

      def kill_container(state)
        container_id = state[:container_id]
        run_command("docker kill #{container_id}")
      end

      def rm_image(state)
        image_id = state[:image_id]
        run_command("docker rmi #{image_id}")
      end
    end
  end
end
