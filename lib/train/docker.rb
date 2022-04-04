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

# Monkey patched Docker train transport to support running the InSpec verifier on Windows
begin
  # Requires train gem with a minimum version of 2.1.0
  require "train"

  module Train::Transports
    # Patched train transport with Windows support for InSpec verifier
    class Docker < Train.plugin(1)
      name "docker"

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
          raise("Can't find Docker container #{@id}")
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

        if @container.info["Platform"] == "windows"
          ["cmd.exe", "/c", cmd]
        else
          ["/bin/sh", "-c", cmd]
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
  logger.debug("[Docker] train gem not found for InSpec verifier. #{e}")
end
