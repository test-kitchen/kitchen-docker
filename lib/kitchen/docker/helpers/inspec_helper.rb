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

# This helper contains a bunch of monkey patches for the InSpec verifier to work 
# with Docker containers on Windows using TCP connections
#
# This helper should be removed when the inspec, docker-api, and train gems have been updated

# Requires train gem with a minimum version of 2.1.0
begin
  require 'docker'
  require 'train'
  require 'kitchen/verifier/inspec'

  # Override API_VERSION constant in docker-api gem to use version 1.24 of the Docker API 
  module Docker
    API_VERSION = '1.24'
  end

  # Add runner options for Docker transport for kitchen-inspec gem
  module Kitchen
    module Docker
      module Helpers
        module InspecHelper
          Kitchen::Verifier::Inspec.class_eval do
            def runner_options_for_docker(config_data)
              # Set value for DOCKER_HOST environment variable for the docker-api gem
              # See the lib/docker.rb file here: https://github.com/swipely/docker-api/blob/master/lib/docker.rb
              # default_socket_url is set to a Unix socket and env_url requires an environment variable to be set
              # This line should not be added to the kitchen-inspec gem
              ENV['DOCKER_HOST'] = config_data[:socket] if !config_data[:socket].nil? && ENV['DOCKER_HOST'].nil?
              opts = {
                'backend' => 'docker',
                'logger' => logger,
                'host' => config_data[:container_id],
              }
              logger.debug "Connect to Container: #{opts['host']}"
              opts
            end
          end
        end
      end
    end
  end

  # Patched train transport with Windows support for InSpec verifier
  module Train::Transports
    class Docker < Train.plugin(1)
      name 'docker'

      include_options Train::Extras::CommandWrapper
      option :host, required: true

      def connection(state = {}, &block)
        opts = merge_options(options, state || {})
        validate_options(opts)

        if @connection && @connection_options == opts
          reuse_connection(&block)
        else
          create_new_connection(opts, &block)
        end
      end

      private

      # Creates a new Docker connection instance and save it for potential future
      # reuse.
      #
      # @param options [Hash] connection options
      # @return [Docker::Connection] a Docker connection instance
      # @api private
      def create_new_connection(options, &block)
        if @connection
          logger.debug("[Docker] shutting previous connection #{@connection}")
          @connection.close
        end

        @connection_options = options
        @connection = Connection.new(options, &block)
      end

      # Return the last saved Docker connection instance.
      #
      # @return [Docker::Connection] a Docker connection instance
      # @api private
      def reuse_connection
        logger.debug("[Docker] reusing existing connection #{@connection}")
        yield @connection if block_given?
        @connection
      end
    end
  end

  class Train::Transports::Docker
    class Connection < BaseConnection
      def initialize(conf)
        super(conf)
        @id = options[:host]
        @container = ::Docker::Container.get(@id) ||
                    fail("Can't find Docker container #{@id}")
        @cmd_wrapper = nil
        @cmd_wrapper = CommandWrapper.load(self, @options)
        self
      end

      def uri
        if @container.nil?
          "docker://#{@id}"
        else
          "docker://#{@container.id}"
        end
      end

      private

      def file_via_connection(path)
        if os.aix?
          Train::File::Remote::Aix.new(self, path)
        elsif os.solaris?
          Train::File::Remote::Unix.new(self, path)
        elsif os.windows?
          Train::File::Remote::Windows.new(self, path)
        else
          Train::File::Remote::Linux.new(self, path)
        end
      end

      def platform_specific_cmd(cmd)
        return cmd if @container.info.nil?
        if @container.info['Platform'] == 'windows'
          return ['cmd.exe', '/c', cmd]
        else
          return ['/bin/sh', '-c', cmd]
        end
      end

      def run_command_via_connection(cmd, &_data_handler)
        cmd = @cmd_wrapper.run(cmd) unless @cmd_wrapper.nil?
        stdout, stderr, exit_status = @container.exec(platform_specific_cmd(cmd))
        CommandResult.new(stdout.join, stderr.join, exit_status)
      rescue ::Docker::Error::DockerError => _
        raise
      rescue => _
        # @TODO: differentiate any other error
        raise
      end
    end
  end
rescue LoadError => e
  # Log a message if kitchen-inspec or any dependent gem cannot be loaded and bail out
  logger.debug("[Docker] Gems not found for InSpec verifier. #{e}")
end
