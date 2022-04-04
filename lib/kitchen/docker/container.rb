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
    class Container
      include Kitchen::Docker::Helpers::CliHelper
      include Kitchen::Docker::Helpers::ContainerHelper
      include Kitchen::Docker::Helpers::FileHelper
      include Kitchen::Docker::Helpers::ImageHelper

      def initialize(config)
        @config = config
      end

      def create(state)
        if container_exists?(state)
          info("Container ID #{state[:container_id]} already exists.")
        elsif !container_exists?(state) && state[:container_id]
          raise ActionFailed, "Container ID #{state[:container_id]} was found in the kitchen state data, "\
                              "but the container does not exist."
        end

        state[:username] = @config[:username]
      end

      def destroy(state)
        info("[Docker] Destroying Docker container #{state[:container_id]}") if state[:container_id]
        remove_container(state) if container_exists?(state)

        if @config[:remove_images] && state[:image_id]
          remove_image(state) if image_exists?(state)
        end
      end

      def hostname(state)
        hostname = "localhost"

        if remote_socket?
          hostname = socket_uri.host
        elsif @config[:use_internal_docker_network]
          hostname = container_ip_address(state)
        end

        hostname
      end

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
