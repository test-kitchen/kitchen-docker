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

require "erb" unless defined?(Erb)
require "json" unless defined?(JSON)
require "shellwords" unless defined?(Shellwords)
require "tempfile" unless defined?(Tempfile)
require "uri" unless defined?(URI)

require "kitchen"
require "kitchen/configurable"
require_relative "../erb_context"
require_relative "cli_helper"

module Kitchen
  module Docker
    # Mixins shared by the driver, transport, and container classes.
    module Helpers
      # rubocop:disable Metrics/ModuleLength
      # Operations against a running container: exec, copy, inspect, remove.
      module ContainerHelper
        include Configurable
        include Kitchen::Docker::Helpers::CliHelper

        # Pulls the container id out of `docker run` output.
        #
        # Docker prints ids in short (12) or full (64) hex form, on their own
        # line. The id is looked for line by line rather than by taking the whole
        # output, because {CliHelper#run_command} returns stdout and stderr
        # together and docker writes warnings to stderr on runs that otherwise
        # succeed -- "WARNING: Published ports are discarded when using host
        # network mode" whenever run_options sets --net=host, and "WARNING: No
        # swap limit support" on hosts whose kernel lacks swap accounting.
        # Treating the whole output as the id failed those runs *after* the
        # container had been created, leaving it running and untracked.
        #
        # @param output [String] the command output, stdout and stderr together
        # @return [String] the container id
        # @raise [Kitchen::ActionFailed] if no id could be found
        def parse_container_id(output)
          container_id = output.lines.map(&:chomp).find do |line|
            [12, 64].include?(line.size) && line.match?(/\A[0-9a-f]+\z/)
          end

          if container_id.nil?
            raise ActionFailed, "Could not parse Docker run output for container ID"
          end

          container_id
        end

        # Renders the configured Dockerfile through ERB.
        #
        # @return [String] the rendered Dockerfile
        def dockerfile_template
          template = IO.read(File.expand_path(config[:dockerfile]))
          context = Kitchen::Docker::ERBContext.new(config.to_hash)
          ERB.new(template).result(context.get_binding)
        end

        # @return [Boolean] whether the configured socket is a TCP one, meaning
        #   the daemon is not on this machine
        def remote_socket?
          config[:socket] ? socket_uri.scheme == "tcp" : false
        end

        # @return [URI] the configured Docker socket
        def socket_uri
          URI.parse(config[:socket])
        end

        # The path to pass to `docker build -f`.
        #
        # With a build context the path has to be relative to it; without one
        # docker reads the Dockerfile from stdin and the absolute path is fine.
        #
        # @param file [File] the temp Dockerfile
        # @return [String] the path to use
        def dockerfile_path(file)
          config[:build_context] ? Pathname.new(file.path).relative_path_from(Pathname.pwd).to_s : file.path
        end

        # @param state [Hash] instance state naming the container
        # @return [Boolean] whether the container is present and running
        def container_exists?(state)
          state[:container_id] && !!docker_command("top #{state[:container_id]}") rescue false
        end

        # Runs a command inside the container.
        #
        # @param state [Hash] instance state naming the container
        # @param command [String] the command to run
        # @return [String] the command's combined output
        # @raise [RuntimeError] if the command fails
        def container_exec(state, command)
          cmd = build_exec_command(state, command)
          docker_command(cmd)
        rescue => e
          raise "Failed to execute command on Docker container. #{e}"
        end

        # Creates a directory inside the container, on Linux or Windows.
        #
        # @param state [Hash] instance state naming the container
        # @param path [String] the directory to create; environment variable
        #   references are expanded first
        # @return [String] the command's combined output
        # @raise [RuntimeError] if the directory cannot be created
        def create_dir_on_container(state, path)
          path = replace_env_variables(state, path)
          cmd = "mkdir -p #{path}"

          if state[:platform].include?("windows")
            psh = "-Command if(-not (Test-Path '#{path}')) { New-Item -Path '#{path}' -Force }"
            cmd = build_powershell_command(psh)
          end

          cmd = build_exec_command(state, cmd)
          docker_command(cmd)
        rescue => e
          raise "Failed to create directory #{path} on container. #{e}"
        end

        # Copies a local file into the container.
        #
        # @param state [Hash] instance state naming the container
        # @param local_file [String] source path
        # @param remote_file [String] destination path inside the container
        # @return [String] the command's combined output
        # @raise [RuntimeError] if the copy fails
        def copy_file_to_container(state, local_file, remote_file)
          debug("Copying local file #{local_file} to #{remote_file} on container")

          remote_file = replace_env_variables(state, remote_file)

          remote_file = "#{state[:container_id]}:#{remote_file}"
          cmd = build_copy_command(local_file, remote_file)
          docker_command(cmd)
        rescue => e
          raise "Failed to copy file #{local_file} to container. #{e}"
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

        # Reads the container's environment.
        #
        # @param state [Hash] instance state naming the container
        # @return [Hash] variable names to values
        def container_env_variables(state)
          # Retrieves all environment variables from inside container
          vars = {}

          if state[:platform].include?("windows")
            cmd = build_powershell_command("-Command [System.Environment]::GetEnvironmentVariables() ^| ConvertTo-Json")
            cmd = build_exec_command(state, cmd)
            stdout = docker_command(cmd, suppress_output: !logger.debug?).strip
            vars = ::JSON.parse(stdout)
          else
            cmd = build_exec_command(state, "printenv")
            stdout = docker_command(cmd, suppress_output: !logger.debug?).strip
            stdout.split("\n").each { |line| vars[line.split("=")[0]] = line.split("=")[1] }
          end

          vars
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        # Expands a container-side environment variable reference in a path.
        #
        # Handles both +$env:TEMP+ and +$TEMP+ forms. The value has to be read from
        # inside the container, since the workstation's environment is unrelated.
        #
        # @param state [Hash] instance state naming the container
        # @param str [String] the string to expand
        # @return [String] the expanded string
        def replace_env_variables(state, str)
          if str.include?("$env:")
            key = str[/\$env:(.*?)(\\|$)/, 1]
            value = container_env_variables(state)[key].to_s.strip
            str = str.gsub("$env:#{key}", value)
          elsif str.include?("$")
            key = str[%r{\$(.*?)(/|$)}, 1]
            value = container_env_variables(state)[key].to_s.strip
            str = str.gsub("$#{key}", value)
          end

          str
        end

        # Runs the container and returns its id.
        #
        # @param state [Hash] instance state naming the image
        # @param transport_port [Integer, nil] container port to publish, if any
        # @return [String] the new container's id
        def run_container(state, transport_port = nil)
          cmd = build_run_command(state[:image_id], transport_port)
          output = docker_command(cmd)
          parse_container_id(output)
        end

        # @param state [Hash] instance state naming the container
        # @return [String] the container's address on the Docker network
        # @raise [Kitchen::ActionFailed] if it cannot be determined
        def container_ip_address(state)
          cmd = "inspect --format '{{ .NetworkSettings.IPAddress }}'"
          cmd << " #{state[:container_id]}"
          docker_command(cmd).strip
        rescue
          raise ActionFailed, "Error getting internal IP of Docker container"
        end

        # Stops and removes the container.
        #
        # @param state [Hash] instance state naming the container
        # @return [void]
        def remove_container(state)
          container_id = state[:container_id]
          docker_command("stop -t 0 #{container_id}")
          docker_command("rm #{container_id}")
        end

        # Dockerfile ENV lines carrying the configured proxy settings.
        #
        # Each is emitted in both lower and upper case, because different tools
        # inside the image read different spellings.
        #
        # @return [String] the ENV lines, empty when no proxy is configured
        def dockerfile_proxy_config
          %i{http_proxy https_proxy no_proxy}.map do |proxy_type|
            proxy_env_vars(proxy_type)
          end.join
        end

        # ENV lines for one proxy setting, in both spellings.
        #
        # @param proxy_type [Symbol] +:http_proxy+, +:https_proxy+, or
        #   +:no_proxy+
        # @return [String] two ENV lines, or empty when that proxy is unset
        def proxy_env_vars(proxy_type)
          return "" unless config[proxy_type]

          value = config[proxy_type]
          "ENV #{proxy_type}=#{value}\nENV #{proxy_type.upcase}=#{value}\n"
        end
      end
      # rubocop:enable Metrics/ModuleLength
    end
  end
end
