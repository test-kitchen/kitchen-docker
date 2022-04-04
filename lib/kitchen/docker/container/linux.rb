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

require "base64" unless defined?(Base64)
require "openssl" unless defined?(OpenSSL)
require "securerandom" unless defined?(SecureRandom)
require "shellwords" unless defined?(Shellwords)

require_relative "../container"
require_relative "../helpers/dockerfile_helper"

module Kitchen
  module Docker
    class Container
      class Linux < Kitchen::Docker::Container
        include Kitchen::Docker::Helpers::DockerfileHelper

        MUTEX_FOR_SSH_KEYS = Mutex.new

        def initialize(config)
          super
        end

        def create(state)
          super

          debug("Creating Linux container")
          generate_keys

          state[:ssh_key] = @config[:private_key]
          state[:image_id] = build_image(state, dockerfile) unless state[:image_id]
          state[:container_id] = run_container(state, 22) unless state[:container_id]
          state[:hostname] = hostname(state)
          state[:port] = container_ssh_port(state)
        end

        def execute(command)
          # Create temp script file and upload files to container
          debug("Executing command on Linux container (Platform: #{@config[:platform]})")
          filename = "docker-#{::SecureRandom.uuid}.sh"
          temp_file = "./.kitchen/temp/#{filename}"
          create_temp_file(temp_file, command)

          remote_path = @config[:temp_dir]
          debug("Creating directory #{remote_path} on container")
          create_dir_on_container(@config, remote_path)

          debug("Uploading temp file #{temp_file} to #{remote_path} on container")
          upload(temp_file, remote_path)

          debug("Deleting temp file from local filesystem")
          ::File.delete(temp_file)

          # Replace any environment variables used in the path and execute script file
          debug("Executing temp script #{remote_path}/#{filename} on container")
          remote_path = replace_env_variables(@config, remote_path)

          container_exec(@config, "/bin/bash #{remote_path}/#{filename}")
        rescue => e
          raise "Failed to execute command on Linux container. #{e}"
        end

        protected

        def generate_keys
          MUTEX_FOR_SSH_KEYS.synchronize do
            if !File.exist?(@config[:public_key]) || !File.exist?(@config[:private_key])
              private_key = OpenSSL::PKey::RSA.new(2048)
              blobbed_key = Base64.encode64(private_key.to_blob).gsub("\n", "")
              public_key = "ssh-rsa #{blobbed_key} kitchen_docker_key"
              File.open(@config[:private_key], "w") do |file|
                file.write(private_key)
                file.chmod(0600)
              end
              File.open(@config[:public_key], "w") do |file|
                file.write(public_key)
                file.chmod(0600)
              end
            end
          end
        end

        def parse_container_ssh_port(output)
          _host, port = output.split(":")
          port.to_i
        rescue => e
          raise ActionFailed, "Could not parse Docker port output for container SSH port. #{e}"
        end

        def container_ssh_port(state)
          return 22 if @config[:use_internal_docker_network]

          output = docker_command("port #{state[:container_id]} 22/tcp")
          parse_container_ssh_port(output)
        rescue => e
          raise ActionFailed, "Docker reports container has no ssh port mapped. #{e}"
        end

        def dockerfile
          return dockerfile_template if @config[:dockerfile]

          from = "FROM #{@config[:image]}"
          platform = dockerfile_platform
          username = @config[:username]
          public_key = IO.read(@config[:public_key]).strip
          homedir = username == "root" ? "/root" : "/home/#{username}"
          base = dockerfile_base_linux(username, homedir)

          custom = ""
          Array(@config[:provision_command]).each do |cmd|
            custom << "RUN #{cmd}\n"
          end

          ssh_key = "RUN echo #{Shellwords.escape(public_key)} >> #{homedir}/.ssh/authorized_keys"

          # Empty string to ensure the file ends with a newline.
          output = [from, dockerfile_proxy_config, platform, base, custom, ssh_key, ""].join("\n")
          debug("--- Start Dockerfile ---")
          debug(output.strip)
          debug("--- End Dockerfile ---")
          output
        end
      end
    end
  end
end
