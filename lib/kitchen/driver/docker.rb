# -*- encoding: utf-8 -*-
#
# Author:: Sean Porter (<portertech@gmail.com>)
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

      default_config :image,    "ubuntu"
      default_config :username, "kitchen"
      default_config :password, "kitchen"

      def create(state)
        state[:image_id]     = create_image(state)
        state[:container_id] = run_container(state)
        state[:hostname]     = container_address(state)
        wait_for_sshd(state[:hostname])
      end

      def destroy(state)
      end

      protected

      def dockerfile
        path = File.join(File.dirname(__FILE__), "docker", "Dockerfile")
        File.expand_path(path)
      end

      def parse_image_id(output)
        output.each_line do |line|
          if line =~ /image id/i
            return line.split(/\s+/).last
          end
        end
        raise ActionFailed, "Could not parse Docker build output for image ID"
      end

      def create_image(state)
        output = run_command("cat #{dockerfile} | docker build -")
        parse_image_id(output)
      end

      def parse_container_id(output)
        container_id = output.chomp
        unless container_id.size == 12
          raise ActionFailed, "Could not parse Docker run output for container ID"
        end
        container_id
      end

      def run_container(state)
        output = run_command("docker run -d #{state[:image_id]} /usr/sbin/sshd -D")
        parse_container_id(output)
      end

      def parse_container_ip(output)
        begin
          info = JSON.parse(output)
          info["NetworkSettings"]["IpAddress"]
        rescue
          raise ActionFailed, "Could not parse Docker inspect output for container IP address"
        end
      end

      def container_address(state)
        output = run_command("docker inspect #{state[:container_id]}")
        parse_container_ip(output)
      end
    end
  end
end
