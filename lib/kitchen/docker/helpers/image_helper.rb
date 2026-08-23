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
require "pathname" unless defined?(Pathname)
require_relative "cli_helper"
require_relative "container_helper"

module Kitchen
  module Docker
    # Mixins shared by the driver, transport, and container classes.
    module Helpers
      # Building, inspecting, and removing Docker images.
      module ImageHelper
        include Configurable
        include Kitchen::Docker::Helpers::CliHelper
        include Kitchen::Docker::Helpers::ContainerHelper

        # Pulls the built image's id out of `docker build` output.
        #
        # Scanned in reverse, and against several patterns, because the wording has
        # changed across Docker and BuildKit versions.
        #
        # @param output [String] the build output
        # @return [String] the image id
        # @raise [Kitchen::ActionFailed] if no id could be found
        def parse_image_id(output)
          output.split("\n").reverse_each do |line|
            if line =~ /writing image (sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i
              img_id = line[/writing image (sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i, 1]
              return img_id
            end
            if line =~ /image id|build successful|successfully built/i
              img_id = line.split(/\s+/).last
              return img_id
            end
            # Docker ~v4.31 support
            if line =~ /naming to moby-dangling@(sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i
              img_id = line[/naming to moby-dangling@(sha256:[[:xdigit:]]{64})(?: \d*\.\ds)? done/i, 1]
              return img_id
            end
          end
          raise ActionFailed, "Could not parse Docker build output for image ID"
        end

        # Removes the built image, unless a container is still using it.
        #
        # @param state [Hash] instance state naming the image
        # @return [void]
        def remove_image(state)
          image_id = state[:image_id]
          if image_in_use?(state)
            info("[Docker] Image ID #{image_id} is in use. Skipping removal")
          else
            info("[Docker] Removing image with Image ID #{image_id}.")
            docker_command("rmi #{image_id}")
          end
        end

        # Whether any container was created from the image.
        #
        # Asked with a filter rather than by searching `docker ps -a` output for
        # the id. That output abbreviates the IMAGE column to twelve characters,
        # while state carries the full +sha256:+ digest, so the substring never
        # matched and the answer was always false -- which defeated the guard
        # entirely and let {#remove_image} run `docker rmi` against an image a
        # container was still using.
        #
        # @param state [Hash] instance state naming the image
        # @return [Boolean] whether any container references it
        def image_in_use?(state)
          return false unless state[:image_id]

          output = docker_command("ps -a -q --filter ancestor=#{state[:image_id]}",
            suppress_output: !logger.debug?)

          # Matched line by line rather than by emptiness, so a warning docker
          # writes to stderr is not mistaken for a container id.
          output.lines.map(&:strip).any? do |line|
            line.match?(/\A[0-9a-f]{12}(?:[0-9a-f]{52})?\z/)
          end
        end

        # Builds the image from the given Dockerfile.
        #
        # The Dockerfile is written to a temp file and also passed on stdin, so the
        # build works both with a build context and without one. The temp file is
        # removed whether or not the build succeeded.
        #
        # @param state [Hash] instance state
        # @param dockerfile [String] the Dockerfile contents
        # @return [String] the new image's id
        # @raise [Kitchen::ActionFailed] if the id cannot be parsed from the output
        def build_image(state, dockerfile)
          cmd = "build"
          cmd << " --no-cache" unless config[:use_cache]
          cmd << " --platform=#{config[:docker_platform]}" if config[:docker_platform]
          extra_build_options = config_to_options(config[:build_options])
          cmd << " #{extra_build_options}" unless extra_build_options.empty?
          dockerfile_contents = dockerfile
          file = Tempfile.new("Dockerfile-kitchen", Pathname.pwd + config[:build_tempdir])
          cmd << " -f #{Shellwords.escape(dockerfile_path(file))}" if config[:build_context]
          build_context = config[:build_context] ? "." : "-"
          output = begin
                     file.write(dockerfile)
                     file.close
                     docker_command("#{cmd} #{build_context}",
                       input: dockerfile_contents,
                       environment: { BUILDKIT_PROGRESS: "plain" })
                   ensure
                     file.close unless file.closed?
                     file.unlink
                   end

          parse_image_id(output)
        end

        # Whether the image named in state is present locally.
        #
        # The inspect is silenced, as every other predicate that shells out to
        # docker is. Left speaking, `kitchen destroy` on an instance with
        # +remove_images+ set printed the image's entire `docker inspect` JSON
        # -- config, every layer digest, metadata -- into the middle of the
        # destroy output, between the container being removed and the image
        # being removed. Nothing read it: only whether the command succeeded is
        # used.
        #
        # It is still printed under `-l debug`, where the rest of the driver's
        # docker traffic is.
        #
        # @param state [Hash] instance state naming the image
        # @return [Boolean] whether the image is present locally
        def image_exists?(state)
          return false unless state[:image_id]

          !!docker_command("inspect --type=image #{state[:image_id]}",
            suppress_output: !logger.debug?)
        rescue
          false
        end
      end
    end
  end
end
