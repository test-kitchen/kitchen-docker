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
end
