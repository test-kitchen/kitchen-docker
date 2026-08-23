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
require "kitchen/configurable"
require "kitchen/logging"
require "kitchen/shell_out"
require "shellwords" unless defined?(Shellwords)

module Kitchen
  module Docker
    # Mixins shared by the driver, transport, and container classes.
    module Helpers
      # rubocop:disable Metrics/ModuleLength
      # Builds and runs docker CLI command lines.
      module CliHelper
        include Configurable
        include Logging
        include ShellOut

        # Escapes a configured value for the shell.
        #
        # Docker command lines are assembled as strings and handed to a shell, so
        # a value that is a single datum -- a path, a name, a port mapping -- has
        # to be escaped, or a space inside it is read as an argument separator and
        # the rest of the value is taken as the image name.
        #
        # Values that are deliberately shell fragments are *not* escaped:
        # +run_command+, +run_options+, +build_options+, and the command handed to
        # `docker exec` are all documented as accepting flags and arguments.
        #
        # Escaping is a no-op for ordinary values -- +db:db+ and +8.8.8.8+ come
        # back unchanged -- so this only alters command lines that were already
        # broken.
        #
        # @param value [#to_s] the configured value
        # @return [String] the value, safe to interpolate into a command line
        def shell_escape(value)
          Shellwords.escape(value.to_s)
        end

        # rubocop:disable Metrics/AbcSize

        # Runs a docker CLI command with the configured connection flags.
        #
        # @param cmd [String] the docker subcommand and its arguments
        # @param options [Hash] shell-out options
        # @return [String] the command's combined stdout and stderr
        def docker_command(cmd, options = {})
          docker = config[:binary].dup
          docker << " -H #{shell_escape(config[:socket])}" if config[:socket]
          docker << " --tls" if config[:tls]
          docker << " --tlsverify" if config[:tls_verify]
          docker << " --tlscacert=#{shell_escape(config[:tls_cacert])}" if config[:tls_cacert]
          docker << " --tlscert=#{shell_escape(config[:tls_cert])}" if config[:tls_cert]
          docker << " --tlskey=#{shell_escape(config[:tls_key])}" if config[:tls_key]
          options = docker_sudo_opts(options)
          logger.debug("docker_command: #{docker} #{cmd} shell_opts: #{docker_shell_opts(options)}")
          run_command("#{docker} #{cmd}", docker_shell_opts(options))
        end
        # rubocop:enable Metrics/AbcSize

        # Adds the sudo options {#run_command} reads, when +use_sudo+ is set.
        #
        # Sudo is a property of the call rather than of the configuration as far
        # as the shell-out layer is concerned: it reads +:use_sudo+ from the
        # options hash it is handed and knows nothing about +config+. So a
        # docker command only runs through sudo if these are passed to it.
        #
        # Without this, +use_sudo+ reached exactly one command -- the
        # `docker` probe in +verify_dependencies+ -- and every build, run,
        # exec, cp, and rm still ran as the invoking user. On a host where the
        # daemon socket needs root, that made the documented answer to
        # "permission denied while trying to connect to the Docker daemon
        # socket" do nothing at all.
        #
        # A copy is returned rather than the hash being edited in place, so a
        # caller that reuses its options hash does not accumulate sudo.
        #
        # @param options [Hash] shell-out options
        # @return [Hash] those options, with sudo added when configured
        def docker_sudo_opts(options = {})
          return options unless config[:use_sudo]

          options = options.merge(use_sudo: true)
          options[:sudo_command] = config[:sudo_command] if config[:sudo_command]
          options
        end

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize

        # Runs a shell command, returning stderr as well as stdout.
        #
        # Test Kitchen's own +run_command+ discards stderr, but docker writes build
        # progress and image ids there, so this reimplements it to keep both.
        #
        # @param cmd [String] the command to run
        # @param options [Hash] shell-out options
        # @return [String] combined stdout and stderr
        # @raise [Kitchen::ShellCommandFailed] if the command exits non-zero
        def run_command(cmd, options = {})
          if options.fetch(:use_sudo, false)
            cmd = "#{options.fetch(:sudo_command, "sudo -E")} #{cmd}"
          end
          subject = "[#{options.fetch(:log_subject, "local")} command]"

          debug("#{subject} BEGIN (#{cmd})")
          sh = Mixlib::ShellOut.new(cmd, shell_opts(options))
          sh.run_command
          debug("#{subject} END #{Util.duration(sh.execution_time)}")
          sh.error!
          sh.stdout + sh.stderr
        rescue Mixlib::ShellOut::ShellCommandFailed => ex
          raise ShellCommandFailed, ex.message
        rescue Exception => error # rubocop:disable Lint/RescueException
          error.extend(Kitchen::Error)
          raise
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize

        # Builds the `docker run` command line from the configuration.
        #
        # @param image_id [String] the image to run
        # @param transport_port [Integer, nil] container port to publish, if any
        # @return [String] the docker subcommand and its arguments
        def build_run_command(image_id, transport_port = nil)
          cmd = "run -d"
          cmd << " -i" if config[:interactive]
          cmd << " -t" if config[:tty]
          cmd << build_env_variable_args(config[:env_variables]) if config[:env_variables]
          cmd << " -p #{transport_port}" unless transport_port.nil?
          Array(config[:forward]).each { |port| cmd << " -p #{shell_escape(port)}" }
          Array(config[:dns]).each { |dns| cmd << " --dns #{shell_escape(dns)}" }
          Array(config[:add_host]).each { |host, ip| cmd << " --add-host=#{shell_escape("#{host}:#{ip}")}" }
          Array(config[:volume]).each { |volume| cmd << " -v #{shell_escape(volume)}" }
          Array(config[:volumes_from]).each { |container| cmd << " --volumes-from #{shell_escape(container)}" }
          Array(config[:links]).each { |link| cmd << " --link #{shell_escape(link)}" }
          Array(config[:devices]).each { |device| cmd << " --device #{shell_escape(device)}" }
          Array(config[:mount]).each { |mount| cmd << " --mount #{shell_escape(mount)}" }
          Array(config[:tmpfs]).each { |tmpfs| cmd << " --tmpfs #{shell_escape(tmpfs)}" }
          cmd << " --name #{shell_escape(config[:instance_name])}" if config[:instance_name]
          cmd << " -P" if config[:publish_all]
          cmd << " -h #{shell_escape(config[:hostname])}" if config[:hostname]
          cmd << " -m #{shell_escape(config[:memory])}" if config[:memory]
          cmd << " -c #{shell_escape(config[:cpu])}" if config[:cpu]
          cmd << " --gpus #{shell_escape(config[:gpus])}" if config[:gpus]
          cmd << " -e http_proxy=#{shell_escape(config[:http_proxy])}" if config[:http_proxy]
          cmd << " -e https_proxy=#{shell_escape(config[:https_proxy])}" if config[:https_proxy]
          cmd << " --privileged" if config[:privileged]
          cmd << " --isolation #{shell_escape(config[:isolation])}" if config[:isolation]
          Array(config[:cap_add]).each { |cap| cmd << " --cap-add=#{shell_escape(cap)}" } if config[:cap_add]
          Array(config[:cap_drop]).each { |cap| cmd << " --cap-drop=#{shell_escape(cap)}" } if config[:cap_drop]
          Array(config[:security_opt]).each { |opt| cmd << " --security-opt=#{shell_escape(opt)}" } if config[:security_opt]
          cmd << " --platform=#{shell_escape(config[:docker_platform])}" if config[:docker_platform]
          extra_run_options = config_to_options(config[:run_options])
          cmd << " #{extra_run_options}" unless extra_run_options.empty?
          # run_command is a command line, not a single value, so it stays raw.
          cmd << " #{shell_escape(image_id)} #{config[:run_command]}"
          logger.debug("build_run_command: #{cmd}")
          cmd
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize

        # Builds a `docker exec` command line from the configuration.
        #
        # @param state [Hash] instance state naming the container
        # @param command [String] the command to run inside it
        # @return [String] the docker subcommand and its arguments
        def build_exec_command(state, command)
          cmd = "exec"
          cmd << " -d" if config[:detach]
          cmd << build_env_variable_args(config[:env_variables]) if config[:env_variables]
          cmd << " --privileged" if config[:privileged]
          cmd << " -t" if config[:tty]
          cmd << " -i" if config[:interactive]
          cmd << " -u #{shell_escape(config[:username])}" if config[:username]
          cmd << " -w #{shell_escape(config[:working_dir])}" if config[:working_dir]
          cmd << " #{shell_escape(state[:container_id])}"
          # command is a command line, not a single value, so it stays raw.
          cmd << " #{command}"
          logger.debug("build_exec_command: #{cmd}")
          cmd
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize

        # Builds a `docker cp` command line.
        #
        # @param local_file [String] source path
        # @param remote_file [String] destination, as +container:path+
        # @param opts [Hash] +:archive+ to preserve ownership and mode
        # @return [String] the docker subcommand and its arguments
        def build_copy_command(local_file, remote_file, opts = {})
          cmd = "cp"
          cmd << " -a" if opts[:archive]
          cmd << " #{shell_escape(local_file)} #{shell_escape(remote_file)}"
          cmd
        end

        # Wraps PowerShell code so it can be run through `docker exec`.
        #
        # @param args [String] the PowerShell arguments
        # @return [String] the full powershell invocation
        def build_powershell_command(args)
          cmd = "powershell -ExecutionPolicy Bypass -NoLogo "
          cmd << args
          logger.debug("build_powershell_command: #{cmd}")
          cmd
        end

        # Turns a hash of environment variables into `-e` flags.
        #
        # @param vars [Hash] variable names to values
        # @return [String] the flags, each preceded by a space
        # @raise [Kitchen::ActionFailed] if given something other than a Hash
        def build_env_variable_args(vars)
          raise ActionFailed, "Environment variables are not of a Hash type" unless vars.is_a?(Hash)

          args = ""
          vars.each do |k, v|
            args << " -e #{shell_escape("#{k.to_s.strip}=#{v.to_s.strip}")}"
          end

          args
        end

        # @return [String] the platform's null device, +NUL+ on Windows and
        #   +/dev/null+ everywhere else
        def dev_null
          case RbConfig::CONFIG["host_os"]
          when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
            "NUL"
          else
            "/dev/null"
          end
        end

        # Normalizes shell-out options for a docker command.
        #
        # Translates +:suppress_output+ into silencing the live stream, and removes
        # it, since Mixlib::ShellOut would reject the unknown key.
        #
        # @param options [Hash] the options to normalize
        # @return [Hash] options Mixlib::ShellOut accepts
        def docker_shell_opts(options = {})
          options[:live_stream] = nil if options[:suppress_output]
          options.delete(:suppress_output)

          options
        end

        # Convert the config input for `:build_options` or `:run_options` in to a
        # command line string for use with Docker.
        #
        # @since 2.5.0
        # @param config [nil, String, Array, Hash] Config data to convert.
        # @return [String]
        # rubocop:disable Metrics/CyclomaticComplexity
        def config_to_options(config)
          case config
          when nil
            ""
          when String
            config
          when Array
            config.map { |c| config_to_options(c) }.join(" ")
          when Hash
            config.map { |k, v| Array(v).map { |c| "--#{k}=#{Shellwords.escape(c)}" }.join(" ") }.join(" ")
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity
      end
      # rubocop:enable Metrics/ModuleLength
    end
  end
end
