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

require "securerandom" unless defined?(SecureRandom)

require_relative "../container"

module Kitchen
  module Docker
    class Container
      class Windows < Kitchen::Docker::Container
        def initialize(config)
          super
        end

        def create(state)
          super

          debug("Creating Windows container")
          state[:username] = @config[:username]
          state[:image_id] = build_image(state, dockerfile) unless state[:image_id]
          state[:container_id] = run_container(state) unless state[:container_id]
          state[:hostname] = hostname(state)
        end

        def execute(command)
          # Create temp script file and upload files to container
          debug("Executing command on Windows container")
          filename = "docker-#{::SecureRandom.uuid}.ps1"
          temp_file = ".\\.kitchen\\temp\\#{filename}"
          create_temp_file(temp_file, command)

          remote_path = @config[:temp_dir].tr("/", "\\")
          debug("Creating directory #{remote_path} on container")
          create_dir_on_container(@config, remote_path)

          debug("Uploading temp file #{temp_file} to #{remote_path} on container")
          upload(temp_file, remote_path)

          debug("Deleting temp file from local filesystem")
          ::File.delete(temp_file)

          # Replace any environment variables used in the path and execute script file
          debug("Executing temp script #{remote_path}\\#{filename} on container")
          remote_path = replace_env_variables(@config, remote_path)
          cmd = build_powershell_command("-File #{remote_path}\\#{filename}")

          container_exec(@config, cmd)
        rescue => e
          raise "Failed to execute command on Windows container. #{e}"
        end

        protected

        def dockerfile
          raise ActionFailed, "Unknown platform '#{@config[:platform]}'" unless @config[:platform] == "windows"
          return dockerfile_template if @config[:dockerfile]

          from = "FROM #{@config[:image]}"

          custom = ""
          Array(@config[:provision_command]).each do |cmd|
            custom << "RUN #{cmd}\n"
          end

          output = [from, dockerfile_proxy_config, custom, ""].join("\n")
          debug("--- Start Dockerfile ---")
          debug(output.strip)
          debug("--- End Dockerfile ---")
          output
        end
      end
    end
  end
end
