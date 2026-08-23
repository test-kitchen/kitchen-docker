#
# Copyright 2016, Noah Kantrowitz
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

describe Kitchen::Driver::Docker do
  # `kitchen diagnose` is what bug reports are asked to include, so what it
  # says about the plugin has to be true. The transport reported
  # Kitchen::VERSION, which is Test Kitchen's version, and the driver reported
  # nothing at all.
  describe "plugin metadata" do
    it "reports this gem's version, not Test Kitchen's" do
      expect(described_class.diagnose[:version]).to eq Kitchen::Docker::DOCKER_VERSION
    end

    it "does not report Test Kitchen's version" do
      expect(described_class.diagnose[:version]).not_to eq Kitchen::VERSION
    end

    it "declares the driver API version it is written against" do
      expect(described_class.diagnose[:api_version]).to eq 2
    end
  end

  describe "#config_to_options" do
    let(:config) {}
    subject { described_class.new.send(:config_to_options, config) }

    context "with nil" do
      let(:config) { nil }
      it { is_expected.to eq "" }
    end # /context with nil

    context "with a string" do
      let(:config) { "--foo" }
      it { is_expected.to eq "--foo" }
    end # /context with a string

    context "with a string with spaces" do
      let(:config) { "--foo bar" }
      it { is_expected.to eq "--foo bar" }
    end # /context with a string with spaces

    context "with an array of strings" do
      let(:config) { %w{--foo --bar} }
      it { is_expected.to eq "--foo --bar" }
    end # /context with an array of strings

    context "with an array of hashes" do
      let(:config) { [{ foo: "bar" }, { other: "baz" }] }
      it { is_expected.to eq "--foo=bar --other=baz" }
    end # /context with an array of hashes

    context "with a hash of strings" do
      let(:config) { { foo: "bar", other: "baz" } }
      it { is_expected.to eq "--foo=bar --other=baz" }
    end # /context with a hash of strings

    context "with a hash of arrays" do
      let(:config) { { foo: %w{bar baz} } }
      it { is_expected.to eq "--foo=bar --foo=baz" }
    end # /context with a hash of arrays

    context "with a hash of strings with spaces" do
      let(:config) { { foo: "bar two", other: "baz" } }
      it { is_expected.to eq '--foo=bar\\ two --other=baz' }
    end # /context with a hash of strings with spaces
  end # /describe #config_to_options

  # `kitchen package`, `kitchen doctor`, and `kitchen list --live` each ask the
  # driver a question. Driver::Base answers all three with a shrug, and this
  # driver used to inherit that: package produced nothing, doctor said nothing,
  # and every instance listed as "unknown". Docker can answer all three.
  def driver(config = {}, instance_name: "default-ubuntu-2404")
    described_class.new(config).tap do |d|
      allow(d).to receive(:instance).and_return(instance_double("Kitchen::Instance", name: instance_name))
      allow(d).to receive(:logger).and_return(double(debug?: false, debug: nil))
      %i{info error debug banner}.each { |level| allow(d).to receive(level) }
    end
  end

  describe "#status" do
    let(:state) { { container_id: "abc123abc123" } }

    def status_of(exists:, running:, state: { container_id: "abc123abc123" })
      d = driver
      allow(d).to receive(:container_exists?).and_return(exists)
      allow(d).to receive(:container_running?).and_return(running)
      d.status(state)
    end

    it "reports a running container as live" do
      expect(status_of(exists: true, running: true))
        .to include(live: true, state: "running", source: "driver")
    end

    it "distinguishes a stopped container from a missing one" do
      expect(status_of(exists: true, running: false)).to include(live: false, state: "stopped")
      expect(status_of(exists: false, running: false)).to include(live: false, state: "gone")
    end

    it "reports an instance with no container as not created" do
      expect(status_of(exists: false, running: false, state: {}))
        .to include(live: false, state: "not created")
    end

    it "names the container so `kitchen list --live` can show it" do
      expect(status_of(exists: true, running: true)[:resource_id]).to eq "abc123abc123"
    end

    it "does not ask docker about an instance that has no container" do
      d = driver
      expect(d).not_to receive(:container_exists?)
      d.status({})
    end

    it "stamps when it looked" do
      expect(status_of(exists: true, running: true)[:checked_at])
        .to match(/\A\d{4}-\d{2}-\d{2}T[\d:]+Z\z/)
    end
  end

  describe "#package" do
    let(:state) { { container_id: "abc123abc123" } }
    let(:digest) { "sha256:#{"a" * 64}" }

    it "commits the container to the configured image name" do
      d = driver({ package_name: "myapp:v1" })
      allow(d).to receive(:container_exists?).and_return(true)
      expect(d).to receive(:docker_command)
        .with("commit abc123abc123 myapp:v1", hash_including(:suppress_output))
        .and_return("#{digest}\n")
      d.package(state)
    end

    it "names the image after the instance by default" do
      d = driver
      expect(d.send(:config)[:package_name]).to eq "default-ubuntu-2404:latest"
    end

    it "escapes a package name that would otherwise split" do
      d = driver({ package_name: "my app:v1" })
      allow(d).to receive(:container_exists?).and_return(true)
      expect(d).to receive(:docker_command)
        .with(%q{commit abc123abc123 my\ app:v1}, hash_including(:suppress_output))
        .and_return("#{digest}\n")
      d.package(state)
    end

    it "refuses to package an instance that was never created" do
      expect { driver.package({}) }
        .to raise_error(Kitchen::ActionFailed, /has not been created/)
    end

    it "does not run docker for an instance that was never created" do
      d = driver
      expect(d).not_to receive(:docker_command)
      expect { d.package({}) }.to raise_error(Kitchen::ActionFailed)
    end

    # `docker commit` on a container that is gone says only "Error response
    # from daemon: No such container: <64 hex characters>", which names neither
    # the instance nor what to do about it.
    it "names the instance when the container is gone" do
      d = driver
      allow(d).to receive(:container_exists?).and_return(false)
      expect { d.package(state) }
        .to raise_error(Kitchen::ActionFailed, /default-ubuntu-2404.*kitchen destroy/m)
    end
  end

  describe "#doctor" do
    let(:state) { {} }

    def doctor_with(config = {}, daemon: "29.7.2", state: {})
      d = driver(config)
      allow(d).to receive(:container_exists?).and_return(true)
      allow(d).to receive(:docker_command) do
        raise Kitchen::ShellOut::ShellCommandFailed, "cannot connect" if daemon.nil?

        "#{daemon}\n"
      end
      d.doctor(state)
    end

    it "reports no problem when the daemon answers" do
      expect(doctor_with).to be false
    end

    it "reports a problem when the daemon cannot be reached" do
      expect(doctor_with(daemon: nil)).to be true
    end

    it "reports a TLS file that is not there" do
      expect(doctor_with({ tls_cert: "/nope/cert.pem" })).to be true
    end

    it "reports a dockerfile that is not there" do
      expect(doctor_with({ dockerfile: "/nope/Dockerfile" })).to be true
    end

    it "accepts paths that do exist" do
      expect(doctor_with({ dockerfile: __FILE__ })).to be false
    end

    it "reports a state file naming a container the daemon does not have" do
      d = driver
      allow(d).to receive(:docker_command).and_return("29.7.2\n")
      allow(d).to receive(:container_exists?).and_return(false)
      expect(d.doctor(container_id: "abc123abc123")).to be true
    end

    it "keeps checking after the first problem, so the whole list is reported" do
      # `kitchen doctor` exists to tell you everything that is wrong at once.
      d = driver({ tls_cert: "/nope/cert.pem", dockerfile: "/nope/Dockerfile" })
      allow(d).to receive(:docker_command).and_raise(Kitchen::ShellOut::ShellCommandFailed, "nope")
      allow(d).to receive(:container_exists?).and_return(false)
      expect(d).to receive(:error).at_least(4).times
      d.doctor(container_id: "abc123abc123")
    end
  end

  describe "socket default config logic" do
    def resolve_socket
      socket = "unix:///var/run/docker.sock"
      socket = "npipe:////./pipe/docker_engine" if Gem.win_platform?
      ENV["DOCKER_HOST"] || socket
    end

    context "on a non-Windows host without DOCKER_HOST set" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("DOCKER_HOST").and_return(nil)
      end

      it "uses the Unix socket" do
        expect(resolve_socket).to eq("unix:///var/run/docker.sock")
      end
    end

    context "on a Windows host without DOCKER_HOST set" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("DOCKER_HOST").and_return(nil)
      end

      it "uses the Windows named pipe" do
        expect(resolve_socket).to eq("npipe:////./pipe/docker_engine")
      end
    end

    context "when DOCKER_HOST env var is set" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("DOCKER_HOST").and_return("tcp://192.168.1.1:2375")
      end

      it "uses DOCKER_HOST over the default socket" do
        expect(resolve_socket).to eq("tcp://192.168.1.1:2375")
      end
    end
  end
end
