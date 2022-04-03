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
require 'kitchen/configurable'
require_relative 'cli_helper'
require_relative 'container_helper'

module Kitchen
  module Docker
    module Helpers
      module ImageHelper
        include Configurable
        include Kitchen::Docker::Helpers::CliHelper
        include Kitchen::Docker::Helpers::ContainerHelper

        def parse_image_id(output)
          output.each_line do |line|
            if line =~ /writing image (sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i
              img_id = line[/writing image (sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i,1]
              return img_id
            end
            if line =~ /image id|build successful|successfully built/i
              img_id = line.split(/\s+/).last
              return img_id
            end
          end
          raise ActionFailed, 'Could not parse Docker build output for image ID'
        end

        def remove_image(state)
          image_id = state[:image_id]
          docker_command("rmi #{image_id}")
        end

        def build_image(state, dockerfile)
          cmd = 'build'
          cmd << ' --no-cache' unless config[:use_cache]
          cmd << " --platform=#{config[:docker_platform]}" if config[:docker_platform]
          extra_build_options = config_to_options(config[:build_options])
          cmd << " #{extra_build_options}" unless extra_build_options.empty?
          dockerfile_contents = dockerfile
          file = Tempfile.new('Dockerfile-kitchen', Dir.pwd)
          cmd << " -f #{Shellwords.escape(dockerfile_path(file))}" if config[:build_context]
          build_context = config[:build_context] ? '.' : '-'
          output = begin
                     file.write(dockerfile)
                     file.close
                     docker_command("#{cmd} #{build_context}",
                                    input: dockerfile_contents,
                                    environment: { BUILDKIT_PROGRESS: 'plain' })
                   ensure
                     file.close unless file.closed?
                     file.unlink
                   end

          parse_image_id(output)
        end

        def image_exists?(state)
          state[:image_id] && !!docker_command("inspect --type=image #{state[:image_id]}") rescue false
        end
      end
    end
  end
end
