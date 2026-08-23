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
  # Test Kitchen's transport plugins.
  module Transport
    # Test Kitchen transport that runs commands inside a Docker container.
    #
    # Commands go through `docker exec` rather than a network protocol, so no
    # SSH or WinRM server is needed inside the image.
    class Docker < Kitchen::Transport::Base
      # Raised when a docker command against the container fails.
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

      # Builds a connection to the container.
      #
      # +DOCKER_HOST+ is exported here because the docker-api gem, used by the
      # InSpec verifier, reads the daemon address from the environment rather
      # than from Test Kitchen's configuration.
      #
      # @param state [Hash] instance state naming the container
      # @yieldparam connection [Connection] if a block is given
      # @return [Connection]
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

      # A connection to one container.
      #
      # The superclass is named in full rather than relying on Ruby resolving
      # the bare `Connection` constant through this class's ancestors.
      class Connection < Kitchen::Transport::Base::Connection
        # Include the InSpec patches to be able to execute tests on Windows containers
        include Kitchen::Docker::Helpers::InspecHelper

        # Runs a command inside the container.
        #
        # @param command [String] the command to run; nil is a no-op
        # @return [void]
        # @raise [DockerFailed] if the command fails
        def execute(command)
          return if command.nil?

          debug("[Docker] Executing command: #{command}")
          info("[Docker] Executing command on container")

          container.execute(command)
        rescue => e
          raise DockerFailed, "Docker failed to execute command on container. Error Details: #{e}"
        end

        # Copies local files into the container.
        #
        # @param locals [String, Array<String>] one path or several
        # @param remote [String] destination path inside the container
        # @return [Array<String>] the files copied
        def upload(locals, remote)
          container.upload(locals, remote)
        end

        # The container implementation for this platform.
        #
        # @return [Kitchen::Docker::Container] a Windows or Linux container
        def container
          @container ||= if windows_container?
                           Kitchen::Docker::Container::Windows.new(@options)
                         else
                           Kitchen::Docker::Container::Linux.new(@options)
                         end
          @container
        end

        # The command `kitchen login` execs to open a shell in the container.
        #
        # Documented here rather than inherited via `(see ...)`, because the
        # superclass lives in the test-kitchen gem and YARD cannot resolve a
        # reference into it from this project's docs.
        #
        # @return [Kitchen::LoginCommand] an interactive `docker exec` session
        def login_command
          argv = build_login_command
          LoginCommand.new(argv.first, argv.drop(1))
        end

        private

        # @return [Boolean] whether the platform under test is Windows
        def windows_container?
          @options[:platform].to_s.include?("windows")
        end

        # Builds the argv array for an interactive `docker exec` session.
        #
        # Kitchen hands the result to `Kernel.exec` in its multi-argument form,
        # which bypasses the shell entirely. Every flag and its value therefore
        # has to be its own token -- a packed "-H unix:///var/run/docker.sock"
        # would reach Docker as a single argument -- and values must not be
        # quoted, since there is no shell to strip the quotes back off.
        #
        # @return [Array<String>] the docker command and its arguments
        def build_login_command
          docker = [@options[:binary]]
          docker.push("-H", @options[:socket]) if @options[:socket]
          docker << "--tls" if @options[:tls]
          docker << "--tlsverify" if @options[:tls_verify]
          docker << "--tlscacert=#{@options[:tls_cacert]}" if @options[:tls_cacert]
          docker << "--tlscert=#{@options[:tls_cert]}" if @options[:tls_cert]
          docker << "--tlskey=#{@options[:tls_key]}" if @options[:tls_key]

          # Always attached, always a TTY: a detached or non-interactive exec
          # would hand back a session the user cannot type into.
          cmd = ["exec"]
          cmd << "--privileged" if @options[:privileged]
          cmd.push("-t", "-i")
          Hash(@options[:env_variables]).each { |key, value| cmd.push("-e", "#{key}=#{value}") }
          cmd.push("-u", @options[:username]) if @options[:username]
          cmd.push("-w", @options[:working_dir]) if @options[:working_dir]
          cmd << @options[:container_id]
          cmd.concat(login_shell)

          logger.debug("build_login_command: #{(docker + cmd).join(" ")}")
          docker + cmd
        end

        # @return [Array<String>] the shell to drop the user into, PowerShell on
        #   Windows and an interactive login bash elsewhere
        def login_shell
          windows_container? ? ["powershell"] : ["/bin/bash", "--login", "-i"]
        end
      end
    end
  end
end
