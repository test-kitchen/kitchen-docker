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

describe Kitchen::Docker::Container do
  subject(:container) { described_class.new(config) }

  let(:config) { { username: "kitchen", remove_images: false } }
  let(:state) { { container_id: "abc123abc123" } }

  # A container that exists but has stopped is the case these two guard. It
  # happens whenever the host reboots, the container's PID 1 exits, or someone
  # runs `docker stop` -- so it is not an exotic state to be in.
  def stub_container(exists:, running:)
    allow(container).to receive(:container_exists?).and_return(exists)
    allow(container).to receive(:container_running?).and_return(running)
  end

  describe "#destroy" do
    it "removes a running container" do
      stub_container(exists: true, running: true)
      expect(container).to receive(:remove_container).with(state)
      container.destroy(state)
    end

    it "removes a container that exists but has stopped" do
      # Test Kitchen deletes the state file once destroy returns, so a stopped
      # container skipped here is orphaned for good: nothing records its id any
      # more, and `kitchen list` reports the instance as not created.
      stub_container(exists: true, running: false)
      expect(container).to receive(:remove_container).with(state)
      container.destroy(state)
    end

    it "removes nothing when the container is already gone" do
      stub_container(exists: false, running: false)
      expect(container).not_to receive(:remove_container)
      container.destroy(state)
    end

    context "with remove_images set" do
      let(:config) { { username: "kitchen", remove_images: true } }
      let(:state) { { container_id: "abc123abc123", image_id: "sha256:abc" } }

      it "removes the image after the container" do
        stub_container(exists: true, running: true)
        allow(container).to receive(:image_exists?).and_return(true)
        order = []
        allow(container).to receive(:remove_container) { order << :container }
        allow(container).to receive(:remove_image) { order << :image }

        container.destroy(state)

        expect(order).to eq %i{container image}
      end
    end
  end

  describe "#create" do
    it "accepts a running container it has seen before" do
      stub_container(exists: true, running: true)
      expect { container.create(state) }.not_to raise_error
    end

    it "records the login user" do
      stub_container(exists: true, running: true)
      new_state = state.dup
      container.create(new_state)
      expect(new_state[:username]).to eq "kitchen"
    end

    it "refuses a container that exists but is not running, and says how to clear it" do
      # Reporting this as "the container does not exist" left no way forward:
      # the container is there, so the message has to point at destroy.
      stub_container(exists: true, running: false)
      expect { container.create(state) }
        .to raise_error(Kitchen::ActionFailed, /is not running.*kitchen destroy/m)
    end

    it "refuses a container that state names but docker does not have" do
      stub_container(exists: false, running: false)
      expect { container.create(state) }
        .to raise_error(Kitchen::ActionFailed, /does not exist/)
    end

    it "is happy to start from nothing" do
      stub_container(exists: false, running: false)
      expect { container.create({}) }.not_to raise_error
    end

    it "asks docker about the container only as often as it needs to" do
      # The previous implementation called container_exists? twice on the path
      # that raises, which is two `docker inspect` round trips for one answer.
      stub_container(exists: false, running: false)
      expect(container).to receive(:container_exists?).once.and_return(false)
      begin
        container.create(state)
      rescue Kitchen::ActionFailed
        nil
      end
    end
  end
  # Where Test Kitchen is told to connect. All three cases produce something
  # that looks like a host, so getting it wrong does not fail here -- it fails
  # later, as a connection timeout against an address nothing is listening on.
  describe "#hostname" do
    it "is localhost for a local daemon, where the port is published" do
      expect(described_class.new(socket: "unix:///var/run/docker.sock").hostname(state))
        .to eq "localhost"
    end

    # The published port is on the machine running the daemon, not on this one.
    it "is the daemon's host when the socket is remote" do
      expect(described_class.new(socket: "tcp://docker.example.com:2376").hostname(state))
        .to eq "docker.example.com"
    end

    it "is the container's own address on the internal network" do
      c = described_class.new(socket: "unix:///var/run/docker.sock", use_internal_docker_network: true)
      allow(c).to receive(:container_ip_address).with(state).and_return("172.17.0.2")
      expect(c.hostname(state)).to eq "172.17.0.2"
    end

    # A remote daemon has no route back to a container address, so the socket
    # host has to win over the internal network.
    it "prefers the daemon's host over the internal network" do
      c = described_class.new(socket: "tcp://docker.example.com:2376", use_internal_docker_network: true)
      expect(c).not_to receive(:container_ip_address)
      expect(c.hostname(state)).to eq "docker.example.com"
    end
  end

  describe "#upload" do
    it "copies a single file" do
      expect(container).to receive(:copy_file_to_container).with(config, "/local/f.rb", "/tmp")
      container.upload("/local/f.rb", "/tmp")
    end

    it "copies every file it is given" do
      copied = []
      allow(container).to receive(:copy_file_to_container) { |_cfg, file, _remote| copied << file }
      container.upload(["/local/a.rb", "/local/b.rb"], "/tmp")
      expect(copied).to eq ["/local/a.rb", "/local/b.rb"]
    end

    it "returns the files it copied" do
      allow(container).to receive(:copy_file_to_container)
      expect(container.upload(["/local/a.rb"], "/tmp")).to eq ["/local/a.rb"]
    end
  end

end
