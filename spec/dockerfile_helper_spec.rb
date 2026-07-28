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
require "kitchen/docker/helpers/dockerfile_helper"

describe Kitchen::Docker::Helpers::DockerfileHelper do
  let(:helper_class) do
    Class.new do
      include Kitchen::Docker::Helpers::DockerfileHelper
      attr_accessor :config

      def initialize(config = {})
        @config = config
      end
    end
  end

  let(:helper) { helper_class.new(platform:) }

  describe "#amazonlinux_platform" do
    let(:platform) { "amazonlinux" }

    it "includes --allowerasing flag for yum install" do
      result = helper.amazonlinux_platform
      expect(result).to include("yum install -y --allowerasing")
    end

    it "installs required packages including curl" do
      result = helper.amazonlinux_platform
      expect(result).to include("sudo openssh-server openssh-clients which curl")
    end

    it "sets container environment variable" do
      result = helper.amazonlinux_platform
      expect(result).to include("ENV container=docker")
    end

    it "generates SSH host key if missing" do
      result = helper.amazonlinux_platform
      expect(result).to include("ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key")
    end
  end

  describe "#rhel_platform" do
    let(:platform) { "rhel" }

    it "does not include --allowerasing flag" do
      result = helper.rhel_platform
      expect(result).not_to include("--allowerasing")
    end

    it "installs required packages including curl if needed" do
      result = helper.rhel_platform
      expect(result).to include("sudo openssh-server openssh-clients which")
      expect(result).to include("which curl || yum install -y curl")
    end
  end

  describe "#dockerfile_platform" do
    context "when platform is amazonlinux" do
      let(:platform) { "amazonlinux" }

      it "calls amazonlinux_platform method" do
        expect(helper).to receive(:amazonlinux_platform).and_call_original
        result = helper.dockerfile_platform
        expect(result).to include("--allowerasing")
      end
    end

    context "when platform is rhel" do
      let(:platform) { "rhel" }

      it "calls rhel_platform method" do
        expect(helper).to receive(:rhel_platform).and_call_original
        result = helper.dockerfile_platform
        expect(result).not_to include("--allowerasing")
      end
    end

    context "when platform is centos" do
      let(:platform) { "centos" }

      it "calls rhel_platform method" do
        expect(helper).to receive(:rhel_platform).and_call_original
        helper.dockerfile_platform
      end
    end

    context "when platform is oraclelinux" do
      let(:platform) { "oraclelinux" }

      it "calls rhel_platform method" do
        expect(helper).to receive(:rhel_platform).and_call_original
        helper.dockerfile_platform
      end
    end
  end
end
