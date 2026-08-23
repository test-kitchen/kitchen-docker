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

describe Kitchen::Docker::Helpers::DockerfileHelper do
  # Every platform name the driver accepts, and the method it must route to.
  # Adding a distribution means adding a `when` branch and a method, and it is
  # easy to add one and forget the other -- the result being a platform that
  # raises "Unknown platform" or, worse, quietly bootstraps with the wrong
  # package manager.
  PLATFORM_ROUTES = {
    "arch" => :arch_platform,
    "debian" => :debian_platform,
    "ubuntu" => :debian_platform,
    "fedora" => :fedora_platform,
    "gentoo" => :gentoo_platform,
    "gentoo-paludis" => :gentoo_paludis_platform,
    "opensuse" => :opensuse_platform,
    "opensuse/leap" => :opensuse_platform,
    "opensuse/tumbleweed" => :opensuse_platform,
    "sles" => :opensuse_platform,
    "rhel" => :rhel_platform,
    "centos" => :rhel_platform,
    "oraclelinux" => :rhel_platform,
    "amazonlinux" => :amazonlinux_platform,
    "centosstream" => :centosstream_platform,
    "almalinux" => :almalinux_platform,
    "rockylinux" => :rockylinux_platform,
    "photon" => :photonos_platform,
  }.freeze

  describe "#dockerfile_platform" do
    PLATFORM_ROUTES.each do |platform, method|
      it "routes #{platform} to ##{method}" do
        # Compared by output rather than by stubbing the method, so this also
        # proves the branch is wired to a method that actually exists.
        h = helper(platform: platform, disable_upstart: true)
        expect(h.dockerfile_platform).to eq h.public_send(method)
      end
    end

    it "names the platform it could not handle" do
      # The error is what a user sees after a typo in kitchen.yml, so it has to
      # contain the value they typed.
      expect { helper(platform: "ubunut").dockerfile_platform }
        .to raise_error(Kitchen::ActionFailed, /Unknown platform 'ubunut'/)
    end
  end

  # Test Kitchen reaches a Linux container over SSH as a sudo-capable user, so
  # an image that lacks either an SSH server or sudo is useless no matter which
  # distribution it is. These hold for every supported platform.
  describe "invariants every platform's setup must satisfy" do
    PLATFORM_ROUTES.values.uniq.each do |method|
      context "##{method}" do
        subject(:fragment) { helper(platform: "ubuntu", disable_upstart: true).public_send(method) }

        it "installs sudo" do
          expect(fragment).to match(/\bsudo\b/)
        end

        it "installs an SSH server" do
          expect(fragment).to match(/openssh|\bssh\b/)
        end

        it "contains only Dockerfile instructions" do
          # Catches a fragment that has picked up a stray shell line, which
          # would fail the build with a parse error rather than anything that
          # points back here.
          instructions = fragment.lines.map(&:strip).reject(&:empty?)
          continued = false
          instructions.each do |line|
            expect(line).to match(/\A(RUN|ENV|ARG|COPY|ADD|WORKDIR|USER)\b/) unless continued
            continued = line.end_with?("\\")
          end
        end
      end
    end
  end

  describe "#amazonlinux_platform" do
    subject(:fragment) { helper(platform: "amazonlinux").amazonlinux_platform }

    it "allows erasing conflicting packages, which Amazon Linux 2023 needs" do
      expect(fragment).to include "--allowerasing"
    end

    it "installs curl" do
      expect(fragment).to match(/curl/)
    end

    it "marks the image as running in a container" do
      expect(fragment).to include "ENV container=docker"
    end

    it "generates an SSH host key only if one is missing" do
      # Regenerating on every build would change the host key under a user who
      # already accepted it.
      expect(fragment).to include '[ -f "/etc/ssh/ssh_host_rsa_key" ] ||'
    end
  end

  describe "#rhel_platform" do
    subject(:fragment) { helper(platform: "rhel").rhel_platform }

    it "does not pass --allowerasing, which older yum does not accept" do
      expect(fragment).not_to include "--allowerasing"
    end

    it "installs curl if it is not already present" do
      expect(fragment).to match(/curl/)
    end
  end

  describe "#debian_platform" do
    it "neutralises initctl when disable_upstart is set" do
      expect(helper(platform: "ubuntu", disable_upstart: true).debian_platform)
        .to include "dpkg-divert"
    end

    it "leaves initctl alone when disable_upstart is false" do
      expect(helper(platform: "ubuntu", disable_upstart: false).debian_platform)
        .not_to include "dpkg-divert"
    end

    it "keeps apt non-interactive either way" do
      # A prompt during the build hangs it until Docker times out.
      [true, false].each do |setting|
        expect(helper(platform: "ubuntu", disable_upstart: setting).debian_platform)
          .to include "ENV DEBIAN_FRONTEND=noninteractive"
      end
    end
  end
end
