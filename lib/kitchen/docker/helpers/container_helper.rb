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
    module Helpers
      module ContainerHelper
        include Configurable
        include Kitchen::Docker::Helpers::CliHelper

        def parse_container_id(output)
          container_id = output.chomp

          unless [12, 64].include?(container_id.size)
            raise ActionFailed, "Could not parse Docker run output for container ID"
          end

          container_id
        end

        def dockerfile_template
          template = IO.read(File.expand_path(config[:dockerfile]))
          context = Kitchen::Docker::ERBContext.new(config.to_hash)
          ERB.new(template).result(context.get_binding)
        end

        def remote_socket?
          config[:socket] ? socket_uri.scheme == "tcp" : false
        end

        def socket_uri
          URI.parse(config[:socket])
        end

        def dockerfile_path(file)
          config[:build_context] ? Pathname.new(file.path).relative_path_from(Pathname.pwd).to_s : file.path
        end

        def container_exists?(state)
          state[:container_id] && !!docker_command("top #{state[:container_id]}") rescue false
        end

        def container_exec(state, command)
          cmd = build_exec_command(state, command)
          docker_command(cmd)
        rescue => e
          raise "Failed to execute command on Docker container. #{e}"
        end

        def create_dir_on_container(state, path)
          path = replace_env_variables(state, path)
          cmd = "mkdir -p #{path}"

          if state[:platform].include?("windows")
            psh = "-Command if(-not (Test-Path \'#{path}\')) { New-Item -Path \'#{path}\' -Force }"
            cmd = build_powershell_command(psh)
          end

          cmd = build_exec_command(state, cmd)
          docker_command(cmd)
        rescue => e
          raise "Failed to create directory #{path} on container. #{e}"
        end

        def copy_file_to_container(state, local_file, remote_file)
          debug("Copying local file #{local_file} to #{remote_file} on container")

          remote_file = replace_env_variables(state, remote_file)

          remote_file = "#{state[:container_id]}:#{remote_file}"
          cmd = build_copy_command(local_file, remote_file)
          docker_command(cmd)
        rescue => e
          raise "Failed to copy file #{local_file} to container. #{e}"
        end

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

        def run_container(state, transport_port = nil)
          cmd = build_run_command(state[:image_id], transport_port)
          output = docker_command(cmd)
          parse_container_id(output)
        end

        def container_ip_address(state)
          cmd = "inspect --format '{{ .NetworkSettings.IPAddress }}'"
          cmd << " #{state[:container_id]}"
          docker_command(cmd).strip
        rescue
          raise ActionFailed, "Error getting internal IP of Docker container"
        end

        def remove_container(state)
          container_id = state[:container_id]
          docker_command("stop -t 0 #{container_id}")
          docker_command("rm #{container_id}")
        end

        def dockerfile_proxy_config
          env_variables = ""
          if config[:http_proxy]
            env_variables << "ENV http_proxy #{config[:http_proxy]}\n"
            env_variables << "ENV HTTP_PROXY #{config[:http_proxy]}\n"
          end

          if config[:https_proxy]
            env_variables << "ENV https_proxy #{config[:https_proxy]}\n"
            env_variables << "ENV HTTPS_PROXY #{config[:https_proxy]}\n"
          end

          if config[:no_proxy]
            env_variables << "ENV no_proxy #{config[:no_proxy]}\n"
            env_variables << "ENV NO_PROXY #{config[:no_proxy]}\n"
          end

          env_variables
        end
      end
    end
  end
end
