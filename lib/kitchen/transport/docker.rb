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

require_relative "../docker/container/linux"
require_relative "../docker/container/windows"

require_relative "../docker/helpers/inspec_helper"

require_relative "../../docker/version"
require_relative "../../train/docker"

module Kitchen
  module Transport
    class Docker < Kitchen::Transport::Base
      class DockerFailed < TransportFailed; end

      kitchen_transport_api_version 1
      plugin_version Kitchen::VERSION

      default_config :binary,        "docker"
      default_config :env_variables, nil
      default_config :interactive,   false
      default_config :privileged,    false
      default_config :tls,           false
      default_config :tls_cacert,    nil
      default_config :tls_cert,      nil
      default_config :tls_key,       nil
      default_config :tls_verify,    false
      default_config :tty,           false
      default_config :working_dir,   nil

      default_config :socket do |transport|
        socket = "unix:///var/run/docker.sock"
        socket = "npipe:////./pipe/docker_engine" if transport.windows_os?
        ENV["DOCKER_HOST"] || socket
      end

      default_config :temp_dir do |transport|
        if transport.windows_os?
          "$env:TEMP"
        else
          "/tmp"
        end
      end

      default_config :username do |transport|
        # Return an empty string to prevent username from being added to Docker
        # command line args for Windows if a username was not specified
        if transport.windows_os?
          nil
        else
          "kitchen"
        end
      end

      def connection(state, &block)
        options = config.to_hash.merge(state)
        options[:platform] = instance.platform.name

        # Set value for DOCKER_HOST environment variable for the docker-api gem
        # This allows Windows systems to use the TCP socket for the InSpec verifier
        # See the lib/docker.rb file here: https://github.com/swipely/docker-api/blob/master/lib/docker.rb
        # default_socket_url is set to a Unix socket and env_url requires an environment variable to be set
        ENV["DOCKER_HOST"] = options[:socket] if !options[:socket].nil? && ENV["DOCKER_HOST"].nil?

        Kitchen::Transport::Docker::Connection.new(options, &block)
      end

      class Connection < Kitchen::Transport::Docker::Connection
        # Include the InSpec patches to be able to execute tests on Windows containers
        include Kitchen::Docker::Helpers::InspecHelper

        def execute(command)
          return if command.nil?

          debug("[Docker] Executing command: #{command}")
          info("[Docker] Executing command on container")

          container.execute(command)
        rescue => e
          raise DockerFailed, "Docker failed to execute command on container. Error Details: #{e}"
        end

        def upload(locals, remote)
          container.upload(locals, remote)
        end

        def container
          @container ||= if @options[:platform].include?("windows")
                           Kitchen::Docker::Container::Windows.new(@options)
                         else
                           Kitchen::Docker::Container::Linux.new(@options)
                         end
          @container
        end
      end
    end
  end
end
