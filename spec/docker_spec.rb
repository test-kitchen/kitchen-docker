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

  # The lazy `default_config` blocks are where most of "it just works with a
  # platform name and nothing else" lives. They were previously exercised by a
  # spec that re-implemented the socket block and asserted on its own copy,
  # which would have passed with the driver's block deleted. These read the
  # values back off a driver, which is what Test Kitchen does.
  describe "default configuration" do
    def configured(config = {}, platform: "ubuntu-24.04")
      described_class.new(config).tap do |d|
        allow(d).to receive(:instance).and_return(
          instance_double("Kitchen::Instance",
            name: "default-#{platform.delete(".")}",
            platform: Kitchen::Platform.new(name: platform))
        )
      end
    end

    describe ":socket" do
      around do |example|
        saved = ENV["DOCKER_HOST"]
        example.run
        saved.nil? ? ENV.delete("DOCKER_HOST") : ENV["DOCKER_HOST"] = saved
      end

      it "defaults to the Unix socket" do
        ENV.delete("DOCKER_HOST")
        allow(Gem).to receive(:win_platform?).and_return(false)
        expect(configured[:socket]).to eq "unix:///var/run/docker.sock"
      end

      it "defaults to the named pipe on a Windows host" do
        ENV.delete("DOCKER_HOST")
        allow(Gem).to receive(:win_platform?).and_return(true)
        expect(configured[:socket]).to eq "npipe:////./pipe/docker_engine"
      end

      # Read lazily rather than at require time, so that a DOCKER_HOST exported
      # after the plugin was loaded -- which is what a shell wrapper or a
      # Rakefile does -- is still honoured.
      it "prefers DOCKER_HOST" do
        ENV["DOCKER_HOST"] = "tcp://192.168.1.1:2375"
        expect(configured[:socket]).to eq "tcp://192.168.1.1:2375"
      end
    end

    describe ":image and :platform" do
      it "derives both from the platform name" do
        d = configured({}, platform: "ubuntu-24.04")
        expect(d[:image]).to eq "ubuntu:24.04"
        expect(d[:platform]).to eq "ubuntu"
      end

      it "leaves a name with no release as a bare image" do
        expect(configured({}, platform: "fedora")[:image]).to eq "fedora"
      end

      # CentOS images are tagged `centos7`, not `7`, so the release needs the
      # distribution name in front of it.
      it "special-cases centos, whose tags carry the distribution name" do
        expect(configured({}, platform: "centos-7")[:image]).to eq "centos:centos7"
      end

      it "drops the point release from a centos tag" do
        expect(configured({}, platform: "centos-6.5")[:image]).to eq "centos:centos6"
      end

      # Documented rather than endorsed: the family is the first segment, so a
      # platform named for a variant needs `platform` set explicitly. Both of
      # these are examples the README tells you to configure by hand.
      it "reads only the first segment as the family" do
        expect(configured({}, platform: "centos-stream-9")[:platform]).to eq "centos"
        expect(configured({}, platform: "gentoo-paludis")[:platform]).to eq "gentoo"
      end

      it "yields to a configured image" do
        expect(configured({ image: "dokken/centos-stream-9" })[:image]).to eq "dokken/centos-stream-9"
      end
    end

    describe ":username" do
      it "is the account the generated Dockerfile creates" do
        expect(configured[:username]).to eq "kitchen"
      end

      # A Windows image has no account to create, and passing `-u` with a name
      # that does not exist there fails every exec.
      it "is unset on Windows, where none is created" do
        expect(configured({}, platform: "windows-2022")[:username]).to be_nil
      end
    end

    describe ":run_command" do
      it "runs sshd in the foreground on Linux" do
        expect(configured[:run_command]).to start_with "/usr/sbin/sshd -D"
      end

      # Windows containers are driven through `docker exec`, so PID 1 only has
      # to stay alive.
      it "keeps a Windows container alive with a long-running ping" do
        expect(configured({}, platform: "windows-2022")[:run_command]).to eq "ping -t localhost"
      end

      it "runs PowerShell on an interactive Windows container" do
        expect(configured({ interactive: true }, platform: "windows-2022")[:run_command])
          .to eq "powershell.exe"
      end
    end

    describe ":build_context" do
      it "sends the working directory to a local daemon" do
        expect(configured({ socket: "unix:///var/run/docker.sock" })[:build_context]).to be true
      end

      # Sending the whole working directory over the network is slow enough to
      # be worth defaulting off.
      it "does not send it to a remote daemon" do
        expect(configured({ socket: "tcp://docker.example.com:2376" })[:build_context]).to be false
      end
    end

    describe ":instance_name" do
      it "starts with the instance it belongs to" do
        expect(configured[:instance_name]).to start_with "defaultubuntu2404-"
      end

      it "is a name Docker accepts" do
        expect(configured[:instance_name]).to match(/\A[a-z0-9][a-z0-9_.-]*\z/)
      end

      # Two instances of the same suite must not collide, which is what lets
      # `kitchen test -c` run them at once.
      it "differs between drivers" do
        expect(configured[:instance_name]).not_to eq configured[:instance_name]
      end
    end

    describe ":package_name" do
      it "names the image after the instance" do
        expect(configured[:package_name]).to eq "default-ubuntu-2404:latest"
      end

      it "is a valid Docker repository name even when the instance name is not" do
        d = described_class.new
        allow(d).to receive(:instance).and_return(
          instance_double("Kitchen::Instance", name: "Default-Ubuntu_24.04")
        )
        expect(d[:package_name]).to eq "default-ubuntu_24.04:latest"
      end
    end
  end

  describe "#container" do
    it "builds a Linux container for a Linux platform" do
      expect(driver_for_platform("ubuntu-24.04").send(:container))
        .to be_a Kitchen::Docker::Container::Linux
    end

    # The two classes generate completely different Dockerfiles and reach the
    # container in completely different ways, so picking the wrong one produces
    # an image that cannot be built rather than a subtly wrong one.
    it "builds a Windows container for a Windows platform" do
      expect(driver_for_platform("windows-2022").send(:container))
        .to be_a Kitchen::Docker::Container::Windows
    end

    it "reuses the same container across calls" do
      d = driver_for_platform("ubuntu-24.04")
      expect(d.send(:container)).to be d.send(:container)
    end

    def driver_for_platform(name)
      described_class.new.tap do |d|
        allow(d).to receive(:instance).and_return(
          instance_double("Kitchen::Instance", name: "default", platform: Kitchen::Platform.new(name: name))
        )
      end
    end
  end

  describe "#destroy" do
    it "hands the container off to be removed" do
      d = driver
      c = instance_double(Kitchen::Docker::Container::Linux)
      allow(d).to receive(:container).and_return(c)
      state = { container_id: "abc123abc123" }
      expect(c).to receive(:destroy).with(state)
      d.destroy(state)
    end
  end

  describe "#create" do
    it "creates the container and then waits for the transport" do
      d = driver
      c = instance_double(Kitchen::Docker::Container::Linux)
      allow(d).to receive(:container).and_return(c)
      state = {}

      expect(c).to receive(:create).with(state).ordered
      expect(d).to receive(:wait_for_transport).with(state).ordered

      d.create(state)
    end
  end

  describe "#wait_for_transport" do
    def driver_waiting(wait)
      d = driver({ wait_for_transport: wait })
      @connection = double("connection")
      transport = double("transport")
      allow(transport).to receive(:connection) { |_state, &blk| blk.call(@connection) }
      allow(d.instance).to receive(:transport).and_return(transport)
      d
    end

    it "waits for the transport to answer before converging" do
      d = driver_waiting(true)
      expect(@connection).to receive(:wait_until_ready)
      d.wait_for_transport({})
    end

    # For a container that is not meant to stay up, waiting is a guaranteed
    # timeout rather than a safety net.
    it "does not wait when told not to" do
      d = driver_waiting(false)
      expect(@connection).not_to receive(:wait_until_ready)
      d.wait_for_transport({})
    end
  end

  describe "#verify_dependencies" do
    it "says how to install Docker when the CLI is not there" do
      d = driver
      allow(d).to receive(:run_command).and_raise(Kitchen::ShellOut::ShellCommandFailed, "not found")
      expect { d.verify_dependencies }
        .to raise_error(Kitchen::UserError, /must first install the Docker CLI/)
    end

    it "says nothing when the CLI runs" do
      d = driver
      allow(d).to receive(:run_command).and_return("")
      expect { d.verify_dependencies }.not_to raise_error
    end

    it "probes through sudo when configured to" do
      d = driver({ use_sudo: true })
      expect(d).to receive(:run_command).with(anything, hash_including(use_sudo: true))
      d.verify_dependencies
    end
  end
end
