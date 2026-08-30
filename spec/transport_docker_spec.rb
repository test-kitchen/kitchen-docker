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
require "kitchen/transport/docker"

describe Kitchen::Transport::Docker do
  # `kitchen diagnose` is what bug reports are asked to include, so what it
  # says about the plugin has to be true.
  describe "plugin metadata" do
    it "reports this gem's version, not Test Kitchen's" do
      expect(described_class.diagnose[:version]).to eq Kitchen::Docker::DOCKER_VERSION
    end

    it "does not report Test Kitchen's version" do
      # It did: `plugin_version Kitchen::VERSION` made a diagnose say the
      # transport was at Test Kitchen's version rather than this gem's.
      expect(described_class.diagnose[:version]).not_to eq Kitchen::VERSION
    end

    it "declares the transport API version it is written against" do
      expect(described_class.diagnose[:api_version]).to eq 1
    end
  end

  def transport(config = {}, platform: "ubuntu-24.04")
    described_class.new(config).tap do |t|
      allow(t).to receive(:instance).and_return(
        instance_double("Kitchen::Instance",
          name: "default", platform: Kitchen::Platform.new(name: platform))
      )
    end
  end

  describe "default configuration" do
    describe ":temp_dir" do
      it "stages uploads under /tmp on Linux" do
        expect(transport[:temp_dir]).to eq "/tmp"
      end

      # Resolved inside the container rather than here, because the
      # workstation's TEMP is unrelated to the container's.
      it "stages uploads under the container's own TEMP on Windows" do
        expect(transport({}, platform: "windows-2022")[:temp_dir]).to eq "$env:TEMP"
      end
    end

    describe ":username" do
      it "runs commands as the account the driver created" do
        expect(transport[:username]).to eq "kitchen"
      end

      # There is no such account in a Windows image, and `-u` with a name that
      # does not exist there fails every exec.
      it "is unset on Windows" do
        expect(transport({}, platform: "windows-2022")[:username]).to be_nil
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
        expect(transport[:socket]).to eq "unix:///var/run/docker.sock"
      end

      it "prefers DOCKER_HOST" do
        ENV["DOCKER_HOST"] = "tcp://192.168.1.1:2375"
        expect(transport[:socket]).to eq "tcp://192.168.1.1:2375"
      end
    end
  end

  describe "#connection" do
    around do |example|
      saved = ENV["DOCKER_HOST"]
      example.run
      saved.nil? ? ENV.delete("DOCKER_HOST") : ENV["DOCKER_HOST"] = saved
    end

    it "hands the connection the state as well as the configuration" do
      ENV.delete("DOCKER_HOST")
      conn = transport({ binary: "docker" }).connection(container_id: "abc123")
      expect(conn.send(:options)).to include(binary: "docker", container_id: "abc123")
    end

    # The container classes decide between the Windows and Linux
    # implementations from this, and it is not in the transport's own config.
    it "records the platform under test" do
      ENV.delete("DOCKER_HOST")
      expect(transport({}, platform: "windows-2022").connection({}).send(:options)[:platform])
        .to eq "windows-2022"
    end

    # The docker-api gem, which the InSpec verifier uses, reads the daemon
    # address from the environment rather than from Test Kitchen's config.
    it "exports the configured socket for the InSpec verifier" do
      ENV.delete("DOCKER_HOST")
      transport({ socket: "tcp://docker.example.com:2376" }).connection({})
      expect(ENV["DOCKER_HOST"]).to eq "tcp://docker.example.com:2376"
    end

    it "leaves a DOCKER_HOST the user already exported alone" do
      ENV["DOCKER_HOST"] = "tcp://mine.example.com:2375"
      transport({ socket: "tcp://docker.example.com:2376" }).connection({})
      expect(ENV["DOCKER_HOST"]).to eq "tcp://mine.example.com:2375"
    end
  end
end

describe Kitchen::Transport::Docker::Connection do
  let(:options) do
    {
      binary: "docker",
      container_id: "abc123",
      platform: "ubuntu-24.04",
      socket: "unix:///var/run/docker.sock",
      username: "kitchen",
    }
  end

  subject(:connection) { described_class.new(options) }

  # The class is declared inside `class Docker < Kitchen::Transport::Base`, so
  # its superclass is reached through Ruby's ancestor constant lookup rather
  # than being spelled out. Pin it, so the inheritance cannot drift.
  it "inherits from the Test Kitchen base connection" do
    expect(described_class.superclass).to be Kitchen::Transport::Base::Connection
  end

  describe "#execute" do
    it "runs the command inside the container" do
      expect(connection.container).to receive(:execute).with("echo hi")
      connection.execute("echo hi")
    end

    # Kitchen calls execute with nil for a provisioner that has nothing to run,
    # such as a suite with an empty run_list.
    it "does nothing when there is no command" do
      expect(connection.container).not_to receive(:execute)
      connection.execute(nil)
    end

    # A bare RuntimeError from the container layer is not something Kitchen
    # recognises, so it surfaces as a stack trace rather than as a failed
    # action naming the instance.
    it "reports a failure as a transport failure" do
      allow(connection.container).to receive(:execute).and_raise("boom")
      expect { connection.execute("echo hi") }
        .to raise_error(Kitchen::Transport::Docker::DockerFailed, /Docker failed to execute command/)
    end
  end

  describe "#upload" do
    it "hands the files to the container" do
      expect(connection.container).to receive(:upload).with(["/local/f.rb"], "/tmp")
      connection.upload(["/local/f.rb"], "/tmp")
    end
  end

  describe "#container" do
    it "builds a Linux container for a Linux platform" do
      expect(connection.container).to be_a Kitchen::Docker::Container::Linux
    end

    it "reuses the same container across calls" do
      expect(connection.container).to be connection.container
    end

    context "on a Windows container" do
      let(:options) { { binary: "docker", container_id: "abc123", platform: "windows-2022" } }

      it "builds a Windows container" do
        expect(connection.container).to be_a Kitchen::Docker::Container::Windows
      end
    end
  end

  describe "#login_command" do
    subject(:login_command) { connection.login_command }

    it "returns a Kitchen::LoginCommand" do
      expect(login_command).to be_a(Kitchen::LoginCommand)
    end

    it "execs the docker binary" do
      expect(login_command.command).to eq "docker"
    end

    it "opens an interactive login shell on a Linux container" do
      expect(login_command.arguments).to eq %w{
        -H unix:///var/run/docker.sock
        exec -t -i -u kitchen abc123 /bin/bash --login -i
      }
    end

    it "passes each flag and its value as separate argv tokens" do
      expect(login_command.arguments).to include("-H", "unix:///var/run/docker.sock")
      expect(login_command.arguments).not_to include("-H unix:///var/run/docker.sock")
    end

    context "on a Windows container" do
      let(:options) do
        {
          binary: "docker",
          container_id: "abc123",
          platform: "windows-2022",
          socket: "tcp://localhost:2375",
          username: nil,
        }
      end

      it "opens a PowerShell session instead of bash" do
        expect(login_command.arguments).to eq %w{
          -H tcp://localhost:2375
          exec -t -i abc123 powershell
        }
      end
    end

    context "with TLS configured" do
      before do
        options.merge!(
          tls: true,
          tls_verify: true,
          tls_cacert: "/certs/ca.pem",
          tls_cert: "/certs/cert.pem",
          tls_key: "/certs/key.pem"
        )
      end

      it "includes the TLS flags before the exec subcommand" do
        expect(login_command.arguments.take(8)).to eq %w{
          -H unix:///var/run/docker.sock
          --tls --tlsverify
          --tlscacert=/certs/ca.pem
          --tlscert=/certs/cert.pem
          --tlskey=/certs/key.pem
          exec
        }
      end
    end

    context "with a working directory and environment variables" do
      before do
        options.merge!(working_dir: "/opt/kitchen", env_variables: { FOO: "bar" })
      end

      it "passes them through to docker exec" do
        expect(login_command.arguments).to include("-w", "/opt/kitchen")
        expect(login_command.arguments).to include("-e", "FOO=bar")
      end
    end

    context "when the transport is configured to detach" do
      before { options.merge!(detach: true) }

      it "still runs attached so the session is usable" do
        expect(login_command.arguments).not_to include("-d")
      end
    end

    context "when the transport is configured as privileged" do
      before { options.merge!(privileged: true) }

      it "keeps the privileged flag" do
        expect(login_command.arguments).to include("--privileged")
      end
    end
  end
end
