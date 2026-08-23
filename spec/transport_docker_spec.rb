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
