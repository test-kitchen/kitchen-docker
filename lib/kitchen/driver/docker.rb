#
# Copyright (C) 2014, Sean Porter
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

require "kitchen"
require "json" unless defined?(JSON)
require "securerandom" unless defined?(SecureRandom)
require "net/ssh" unless defined?(Net::SSH)

require "kitchen/driver/base"

require_relative "../docker/container/linux"
require_relative "../docker/container/windows"
require_relative "../docker/helpers/cli_helper"
require_relative "../docker/helpers/container_helper"

module Kitchen
  module Driver
    # Docker driver for Kitchen.
    #
    # @author Sean Porter <portertech@gmail.com>
    class Docker < Kitchen::Driver::Base
      include Kitchen::Docker::Helpers::CliHelper
      include Kitchen::Docker::Helpers::ContainerHelper
      include ShellOut

      default_config :binary,        "docker"
      default_config :build_options, nil
      default_config :build_tempdir, Dir.pwd
      default_config :cap_add,       nil
      default_config :cap_drop,      nil
      default_config :disable_upstart, true
      default_config :env_variables, nil
      default_config :isolation,     nil
      default_config :interactive,   false
      default_config :private_key,   File.join(Dir.pwd, ".kitchen", "docker_id_rsa")
      default_config :privileged,    false
      default_config :public_key,    File.join(Dir.pwd, ".kitchen", "docker_id_rsa.pub")
      default_config :publish_all,   false
      default_config :remove_images, false
      default_config :run_options,   nil
      default_config :security_opt,  nil
      default_config :tls,           false
      default_config :tls_cacert,    nil
      default_config :tls_cert,      nil
      default_config :tls_key,       nil
      default_config :tls_verify,    false
      default_config :tty,           false
      default_config :use_cache,     true
      default_config :use_internal_docker_network, false
      default_config :use_sudo, false
      default_config :wait_for_transport, true

      default_config :build_context do |driver|
        !driver.remote_socket?
      end

      default_config :image do |driver|
        driver.default_image
      end

      default_config :instance_name do |driver|
        # Borrowed from kitchen-rackspace
        [
          driver.instance.name.gsub(/\W/, ""),
          (Etc.getlogin || "nologin").gsub(/\W/, ""),
          Socket.gethostname.gsub(/\W/, "")[0..20],
          Array.new(8) { rand(36).to_s(36) }.join,
        ].join("-").downcase
      end

      default_config :platform do |driver|
        driver.default_platform
      end

      default_config :run_command do |driver|
        if driver.windows_os?
          # Launch arbitrary process to keep the Windows container alive
          # If running in interactive mode, launch powershell.exe instead
          if driver[:interactive]
            "powershell.exe"
          else
            "ping -t localhost"
          end
        else
          "/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no -o PasswordAuthentication=yes "\
          "-o UsePrivilegeSeparation=no -o PidFile=/tmp/sshd.pid"
        end
      end

      default_config :socket do |driver|
        socket = "unix:///var/run/docker.sock"
        socket = "npipe:////./pipe/docker_engine" if driver.windows_os?
        ENV["DOCKER_HOST"] || socket
      end

      default_config :username do |driver|
        # Return nil to prevent username from being added to Docker
        # command line args for Windows if a username was not specified
        if driver.windows_os?
          nil
        else
          "kitchen"
        end
      end

      def verify_dependencies
        run_command("#{config[:binary]} >> #{dev_null} 2>&1", quiet: true, use_sudo: config[:use_sudo])
      rescue
        raise UserError, "You must first install the Docker CLI tool https://www.docker.com/get-started"
      end

      def create(state)
        container.create(state)

        wait_for_transport(state)
      end

      def destroy(state)
        container.destroy(state)
      end

      def wait_for_transport(state)
        if config[:wait_for_transport]
          instance.transport.connection(state) do |conn|
            conn.wait_until_ready
          end
        end
      end

      def default_image
        platform, release = instance.platform.name.split("-")
        if platform == "centos" && release
          release = "centos" + release.split(".").first
        end
        release ? [platform, release].join(":") : platform
      end

      def default_platform
        instance.platform.name.split("-").first
      end

      protected

      def container
        @container ||= if windows_os?
                         Kitchen::Docker::Container::Windows.new(config)
                       else
                         Kitchen::Docker::Container::Linux.new(config)
                       end
        @container
      end
    end
  end
end
