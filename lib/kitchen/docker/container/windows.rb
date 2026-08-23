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
      # A Windows container, driven through `docker exec`.
      #
      # There is no SSH server and no key to inject: commands are uploaded as
      # PowerShell scripts and executed in the container directly, so no port
      # is published.
      class Windows < Kitchen::Docker::Container
        # @param config [Hash] the driver configuration
        def initialize(config)
          super
        end

        # Builds the image and runs the container.
        #
        # No port is published: Windows containers are driven through `docker exec`
        # rather than SSH, so there is nothing to map.
        #
        # @param state [Hash] mutable instance state; gains +username+, +image_id+,
        #   +container_id+, and +hostname+
        # @return [void]
        def create(state)
          super

          debug("Creating Windows container")
          state[:username] = @config[:username]
          state[:image_id] = build_image(state, dockerfile) unless state[:image_id]
          state[:container_id] = run_container(state) unless state[:container_id]
          state[:hostname] = hostname(state)
        end

        # Runs a command in the container by uploading it as a PowerShell script.
        #
        # @param command [String] the PowerShell code to run
        # @return [String] the command's combined output
        # @raise [RuntimeError] if the command fails
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

          # Replace any environment variables used in the path and execute script file
          debug("Executing temp script #{remote_path}\\#{filename} on container")
          remote_path = replace_env_variables(@config, remote_path)
          cmd = build_powershell_command("-File #{remote_path}\\#{filename}")

          container_exec(@config, cmd)
        rescue => e
          raise "Failed to execute command on Windows container. #{e}"
        ensure
          # Removed here rather than after the upload, so that a failure part
          # way through does not leave the script behind in .kitchen/temp.
          if temp_file && ::File.exist?(temp_file)
            debug("Deleting temp file from local filesystem")
            ::File.delete(temp_file)
          end
        end

        protected

        # Builds the Dockerfile for a Windows container.
        #
        # Much shorter than the Linux equivalent: there is no SSH server and no
        # key to inject, so only the base image, proxy settings, and any
        # +provision_command+ entries are emitted.
        #
        # @return [String] the Dockerfile contents
        # @raise [Kitchen::ActionFailed] if the platform is not +windows+
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
