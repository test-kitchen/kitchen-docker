# -*- encoding: utf-8 -*-
#
# Author:: Rene Martin (<rene_martin@intuit.com>)
#
# Copyright (C) 2019, Rene Martin
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
require 'docker'

module Kitchen
  module Transport

    # Wrapped exception for any internally raised errors.
    class DockerExecFailed < TransportFailed; end

    # Docker transport for Kitchen. This transport uses the docker api to
    # copy and run commands in the running container.
    class Docker < Kitchen::Transport::Base
      kitchen_transport_api_version 1

      plugin_version Kitchen::VERSION

      default_config :socket, ENV['DOCKER_HOST'] || 'unix:///var/run/docker.sock'
      default_config :shell , '/bin/sh'

      def connection(state, &block)
        options = config.to_hash.merge(state)
        Kitchen::Transport::Docker::Connection.new(options, &block)
      end

      class Connection < Kitchen::Transport::Base::Connection
        def initialize(opts)
          @opts = opts
          super
        end

        def docker_connection
          @docker_connection ||= ::Docker::Connection.new(@opts[:socket], {})
        end

        def execute(command)
          return if command.nil?

          @runner = ::Docker::Container.get(@opts[:container_id], {}, docker_connection)
          o = @runner.exec([@opts[:shell], '-c', command], wait: 600, 'e' => { 'TERM' => 'xterm' }) { |_stream, chunk| print chunk.to_s }
          @exit_code = o[2]

          raise Transport::DockerExecFailed.new("Docker Exec (#{@exit_code}) for command: [#{command}]", @exit_code) if @exit_code != 0
        end

        def upload(locals, remote)
          @runner = ::Docker::Container.get(@opts[:container_id], {}, docker_connection)
          Array(locals).each do |local|
            full_remote = File.join(remote, File.basename(local))
            # Workarround for archive_in bug https://github.com/swipely/docker-api/issues/359
            if File.directory? local
              tarball = ::Docker::Util.create_dir_tar(local)
              @runner.exec(['mkdir', full_remote])
              @runner.archive_in_stream(full_remote, overwrite: true) { tarball.read(Excon.defaults[:chunk_size]).to_s }
            else
              @runner.archive_in([local], File.dirname(full_remote))
            end
          end
        end

        def login_command
          cols = `tput cols`
          lines = `tput lines`
          args = ['exec', '-e', "COLUMNS=#{cols}", '-e', "LINES=#{lines}", '-it', @opts[:container_id], @opts[:shell], '-login', '-i']
          LoginCommand.new('docker', args)
        end
      end
    end
  end
end
