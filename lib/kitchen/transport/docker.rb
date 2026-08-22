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

# require_relative "../../docker/version"

module Kitchen
  module Transport
    class Docker < Kitchen::Transport::Base
      class DockerFailed < TransportFailed; end

      # kitchen_transport_api_version 1
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
        socket = "npipe:////./pipe/docker_engine" if Gem.win_platform?
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

        def login_command
          config = container.instance_variable_get(:@config)
          login_config = config.dup
          login_config[:interactive] = true
          login_config[:tty] = true
          login_config[:detach] = false
          login_config[:username] = nil
          login_cmd = build_login_command(login_config)
          LoginCommand.new(login_cmd[0], login_cmd[1..-1])
        end

        def build_login_command(config)
          # This function duplicates a lot of CliHelper functionality, but I think I'd need to refactor
          # things to override some aspects of Configurable in order to reuse that code.
          docker = [config[:binary].dup]
          docker << "-H #{config[:socket]}" if config[:socket]
          docker << "--tls" if config[:tls]
          docker << "--tlsverify" if config[:tls_verify]
          docker << "--tlscacert=#{config[:tls_cacert]}" if config[:tls_cacert]
          docker << "--tlscert=#{config[:tls_cert]}" if config[:tls_cert]
          docker << "--tlskey=#{config[:tls_key]}" if config[:tls_key]
          logger.debug("docker_command: #{docker.join(" ")}")

          cmd = ["exec"]
          cmd << "-d" if config[:detach]
          if config[:env_variables]
            config[:env_variables].each do |var|
              cmd << "-e #{var}"
            end
          end
          cmd << "--privileged" if config[:privileged]
          cmd << "-t" if config[:tty]
          cmd << "-i" if config[:interactive]
          cmd << "-u #{config[:username]}" if config[:username]
          cmd << "-w #{config[:working_dir]}" if config[:working_dir]
          cmd << "#{config[:container_id]}"
          cmd << "/bin/bash"
          cmd << "-login"
          cmd << "-i"
          logger.debug("build_exec_command: #{cmd.join(" ")}")
          docker + cmd
        end
      end
    end
  end
end
