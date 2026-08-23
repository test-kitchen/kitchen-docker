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

require_relative "helpers/cli_helper"
require_relative "helpers/container_helper"
require_relative "helpers/file_helper"
require_relative "helpers/image_helper"

module Kitchen
  module Docker
    # Base class for the container the instance under test runs in.
    #
    # Holds the behaviour that is the same on every platform -- checking
    # whether the container exists, removing it, working out its address, and
    # copying files in. {Linux} and {Windows} add how the image is built and
    # how commands are run, which share almost nothing.
    class Container
      include Kitchen::Docker::Helpers::CliHelper
      include Kitchen::Docker::Helpers::ContainerHelper
      include Kitchen::Docker::Helpers::FileHelper
      include Kitchen::Docker::Helpers::ImageHelper

      # @param config [Hash] the driver or transport configuration
      def initialize(config)
        @config = config
      end

      # Checks the container named in state and records the login user.
      #
      # A state file naming a container that no longer exists is an error rather
      # than something to build over, because the stale id usually means the
      # container was removed behind Test Kitchen's back and silently creating a
      # new one would hide that.
      #
      # @param state [Hash] mutable instance state; gains +username+
      # @return [void]
      # @raise [Kitchen::ActionFailed] if state names a container that is gone
      def create(state)
        if container_exists?(state)
          info("Container ID #{state[:container_id]} already exists.")
        elsif !container_exists?(state) && state[:container_id]
          raise ActionFailed, "Container ID #{state[:container_id]} was found in the kitchen state data, " \
                              "but the container does not exist."
        end

        state[:username] = @config[:username]
      end

      # Removes the container, and its image when +remove_images+ is set.
      #
      # @param state [Hash] instance state naming the container
      # @return [void]
      def destroy(state)
        info("[Docker] Destroying Docker container #{state[:container_id]}") if state[:container_id]
        remove_container(state) if container_exists?(state)

        if @config[:remove_images] && state[:image_id]
          remove_image(state) if image_exists?(state)
        end
      end

      # Works out the address Test Kitchen should connect to.
      #
      # A remote Docker socket means the container is reachable at the socket's
      # own host; +use_internal_docker_network+ means its container IP; anything
      # else is a published port on localhost.
      #
      # @param state [Hash] instance state naming the container
      # @return [String] a hostname or IP address
      def hostname(state)
        hostname = "localhost"

        if remote_socket?
          hostname = socket_uri.host
        elsif @config[:use_internal_docker_network]
          hostname = container_ip_address(state)
        end

        hostname
      end

      # Copies local files into the container.
      #
      # @param locals [String, Array<String>] one path or several
      # @param remote [String] destination path inside the container
      # @return [Array<String>] the files copied
      def upload(locals, remote)
        files = locals
        files = Array(locals) unless locals.is_a?(Array)

        files.each do |file|
          copy_file_to_container(@config, file, remote)
        end

        files
      end
    end
  end
end
