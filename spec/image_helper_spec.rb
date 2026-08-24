#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Kitchen::Docker::Helpers::ImageHelper do
  describe "#parse_image_id" do
    # From #225. `docker build -q` prints the id on a line of its own and
    # nothing else -- no "writing image", no "naming to", no "successfully
    # built" -- so every pattern the parser had missed it, and a build with
    # `build_options: -q` failed with "Could not parse Docker build output for
    # image ID" rather than producing an instance.
    context "with a quiet build" do
      it "reads the id docker printed on its own" do
        expect(helper.parse_image_id(DockerOutput::BUILD_QUIET))
          .to eq DockerOutput::BUILD_QUIET_IMAGE_ID
      end

      it "reads it when docker also wrote a warning to stderr" do
        expect(helper.parse_image_id("WARNING: something happened\n#{DockerOutput::BUILD_QUIET}"))
          .to eq DockerOutput::BUILD_QUIET_IMAGE_ID
      end

      it "does not mistake a digest that is part of a longer line for the id" do
        # Ordinary build output is full of "... sha256:... done" lines. Only a
        # line that is nothing but a digest is the quiet form.
        expect { helper.parse_image_id("#6 exporting manifest sha256:#{"a" * 64} done\n") }
          .to raise_error(Kitchen::ActionFailed)
      end
    end

    # Docker has changed how it reports the built image's id several times, and
    # each change has broken this parser. Every format the driver claims to
    # support gets a case here, against output copied from a real build.
    {
      "Docker 29.7 with BuildKit" =>
        [DockerOutput::BUILD_29_7_BUILDKIT, DockerOutput::BUILD_29_7_IMAGE_ID],
      "BuildKit emitting 'writing image'" =>
        [DockerOutput::BUILD_BUILDKIT_WRITING_IMAGE, DockerOutput::BUILD_BUILDKIT_WRITING_IMAGE_ID],
      "the pre-BuildKit builder" =>
        [DockerOutput::BUILD_LEGACY, DockerOutput::BUILD_LEGACY_IMAGE_ID],
    }.each do |description, (output, expected_id)|
      context "with output from #{description}" do
        it "finds the image id" do
          expect(helper.parse_image_id(output)).to eq expected_id
        end

        it "returns something that looks like an image id" do
          # Two of the three patterns pull the id out with a bare `split.last`,
          # which will return whatever trailing token a matching line happens to
          # end with. Asserting the shape catches a match on the wrong line.
          expect(helper.parse_image_id(output)).to match(/\A(sha256:[0-9a-f]{64}|[0-9a-f]{12})\z/)
        end
      end
    end

    it "fails loudly when the output holds no image id" do
      # Returning nil here would put nil into state[:image_id] and fail much
      # later, while `docker run` complained about an empty image name.
      expect { helper.parse_image_id("#1 [internal] load build definition\n#1 DONE 0.0s\n") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker build output/)
    end

    it "fails loudly on empty output" do
      expect { helper.parse_image_id("") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker build output/)
    end

    it "prefers the last id in the output" do
      # The scan runs in reverse so that a rebuild's final export wins over
      # anything earlier in the log.
      doubled = DockerOutput::BUILD_BUILDKIT_WRITING_IMAGE + DockerOutput::BUILD_29_7_BUILDKIT
      expect(helper.parse_image_id(doubled)).to eq DockerOutput::BUILD_29_7_IMAGE_ID
    end
  end

  describe "#build_image" do
    # build_image writes a temp Dockerfile and shells out. Stubbing the shell-out
    # leaves the part worth testing: the command line it assembles.
    let(:built) { [] }

    def build(config = {})
      h = helper({ build_tempdir: ".", build_context: false, use_cache: true }.merge(config))
      allow(h).to receive(:docker_command) do |cmd, _opts|
        built << cmd
        DockerOutput::BUILD_29_7_BUILDKIT
      end
      h.build_image({}, "FROM alpine:3.20\n")
      argv(built.last)
    end

    it "builds, reading the Dockerfile from stdin when there is no build context" do
      expect(build).to eq %w{build -}
    end

    it "passes a build context as the final argument when one is configured" do
      expect(build(build_context: true).last).to eq "."
    end

    it "names the Dockerfile with -f when there is a build context" do
      expect(build(build_context: true)).to include "-f"
    end

    it "disables the cache when use_cache is false" do
      expect(build(use_cache: false)).to include "--no-cache"
    end

    it "uses the cache when use_cache is true, as the driver defaults it" do
      expect(build).not_to include "--no-cache"
    end

    it "passes docker_platform through" do
      expect(build(docker_platform: "linux/arm64")).to include "--platform=linux/arm64"
    end

    it "appends build_options" do
      expect(build(build_options: { "build-arg" => "VERSION=1.2.3" }))
        .to include "--build-arg=VERSION=1.2.3"
    end

    it "returns the parsed image id" do
      h = helper(build_tempdir: ".", build_context: false, use_cache: true)
      allow(h).to receive(:docker_command).and_return(DockerOutput::BUILD_29_7_BUILDKIT)
      expect(h.build_image({}, "FROM alpine:3.20\n")).to eq DockerOutput::BUILD_29_7_IMAGE_ID
    end

    it "removes the temp Dockerfile even when the build fails" do
      # A failed build that leaves Dockerfile-kitchen files behind pollutes the
      # cookbook directory, and they end up in the next build's context.
      before = Dir.glob("Dockerfile-kitchen*")
      h = helper(build_tempdir: ".", build_context: false, use_cache: true)
      allow(h).to receive(:docker_command).and_raise(Kitchen::ShellOut::ShellCommandFailed, "boom")
      expect { h.build_image({}, "FROM alpine:3.20\n") }.to raise_error(Kitchen::ShellOut::ShellCommandFailed)
      expect(Dir.glob("Dockerfile-kitchen*")).to eq before
    end
  end

  describe "#image_in_use?" do
    let(:image_id) { "sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc" }

    def helper_seeing(output)
      h = helper
      @asked = nil
      allow(h).to receive(:docker_command) { |cmd, _opts = {}| @asked = cmd; output }
      h
    end

    it "reports the image as in use when a container references it" do
      expect(helper_seeing("331a7cd151e4\n").image_in_use?(image_id: image_id)).to be true
    end

    it "reports the image as free when nothing references it" do
      expect(helper_seeing("").image_in_use?(image_id: image_id)).to be false
    end

    it "reports the image as free when state names no image" do
      h = helper
      expect(h).not_to receive(:docker_command)
      expect(h.image_in_use?({})).to be false
    end

    it "asks docker to filter, rather than searching ps output for the id" do
      # `docker ps -a` abbreviates the IMAGE column to twelve characters, so
      # searching it for the full sha256 digest never matched and the guard
      # was always false.
      h = helper_seeing("331a7cd151e4\n")
      h.image_in_use?(image_id: image_id)
      expect(@asked).to eq "ps -a -q --filter ancestor=#{image_id}"
    end

    it "does not mistake a warning on stderr for a container" do
      expect(helper_seeing("WARNING: something happened\n").image_in_use?(image_id: image_id))
        .to be false
    end
  end

  describe "#remove_image" do
    let(:state) { { image_id: "sha256:abc" } }

    it "removes the image when nothing is using it" do
      h = helper
      allow(h).to receive(:image_in_use?).and_return(false)
      expect(h).to receive(:docker_command).with("rmi sha256:abc")
      h.remove_image(state)
    end

    it "leaves the image alone when a container still references it" do
      h = helper
      allow(h).to receive(:image_in_use?).and_return(true)
      expect(h).not_to receive(:docker_command)
      h.remove_image(state)
    end
  end

  describe "#image_exists?" do
    let(:state) { { image_id: "sha256:abc" } }

    def asking(&answer)
      helper.tap do |h|
        @opts = nil
        allow(h).to receive(:logger).and_return(double(debug?: false, debug: nil))
        allow(h).to receive(:docker_command) { |_cmd, opts = {}| @opts = opts; answer.call }
      end
    end

    it "is true when docker knows the image" do
      expect(asking { "[{}]" }.image_exists?(state)).to be true
    end

    it "is false when docker does not" do
      expect(asking { raise Kitchen::ShellOut::ShellCommandFailed, "no such image" }
        .image_exists?(state)).to be false
    end

    it "does not ask about an image that state does not name" do
      h = helper
      expect(h).not_to receive(:docker_command)
      expect(h.image_exists?({})).to be false
    end

    # `kitchen destroy` with remove_images set printed the image's whole
    # inspect JSON -- config, every layer digest, metadata -- between removing
    # the container and removing the image. Only whether the command succeeded
    # is used here, as in every other predicate in this file, all of which
    # already silence their output.
    it "does not print the inspect output" do
      asking { "[{}]" }.image_exists?(state)
      expect(@opts).to eq(suppress_output: true)
    end

    it "still prints it under -l debug" do
      h = helper
      allow(h).to receive(:logger).and_return(double(debug?: true, debug: nil))
      allow(h).to receive(:docker_command) { |_cmd, opts = {}| @opts = opts; "[{}]" }
      h.image_exists?(state)
      expect(@opts).to eq(suppress_output: false)
    end
  end
end
