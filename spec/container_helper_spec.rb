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

describe Kitchen::Docker::Helpers::ContainerHelper do
  describe "#parse_container_id" do
    it "accepts a full-length id" do
      expect(helper.parse_container_id(DockerOutput::RUN_CLEAN))
        .to eq DockerOutput::RUN_CONTAINER_ID
    end

    it "accepts a short id" do
      expect(helper.parse_container_id("abc123abc123\n")).to eq "abc123abc123"
    end

    it "fails loudly when the output holds no id" do
      expect { helper.parse_container_id("Error response from daemon: no such image\n") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker run output/)
    end

    it "fails loudly on empty output" do
      expect { helper.parse_container_id("") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker run output/)
    end

    # Cases from #452. Rootless Docker emits this on every `docker run`, which
    # makes it the most common way to reach this code path.
    context "when docker wrote a warning to stderr" do
      let(:warning) { "WARNING: IPv4 forwarding is disabled. Networking will not work." }

      it "finds an id the warning follows" do
        expect(helper.parse_container_id("#{DockerOutput::RUN_CONTAINER_ID}\n#{warning}\n"))
          .to eq DockerOutput::RUN_CONTAINER_ID
      end

      it "finds an id the warning precedes" do
        expect(helper.parse_container_id("#{warning}\n#{DockerOutput::RUN_CONTAINER_ID}\n"))
          .to eq DockerOutput::RUN_CONTAINER_ID
      end

      it "finds a short id" do
        expect(helper.parse_container_id("abcdef123456\n#{warning}\n")).to eq "abcdef123456"
      end

      it "still fails when the warning is all there is" do
        expect { helper.parse_container_id("#{warning}\nno container id here") }
          .to raise_error(Kitchen::ActionFailed, /Could not parse Docker run output/)
      end
    end

    it "takes the id docker printed, not a later hex line" do
      # run_command concatenates stdout before stderr, so the id always comes
      # first. Scanning backwards would prefer a bare hex line that a warning
      # happened to leave on stderr.
      expect(helper.parse_container_id("#{DockerOutput::RUN_CONTAINER_ID}\ndeadbeefcafe\n"))
        .to eq DockerOutput::RUN_CONTAINER_ID
    end

    it "does not mistake a hex-looking word inside a message for an id" do
      expect { helper.parse_container_id("WARNING: layer abcdef123456 was skipped\n") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker run output/)
    end

    it "tolerates surrounding whitespace on the id line" do
      expect(helper.parse_container_id("  #{DockerOutput::RUN_CONTAINER_ID}  \n"))
        .to eq DockerOutput::RUN_CONTAINER_ID
    end

    # run_command returns stdout + stderr, and the parser requires the whole
    # combined string to be exactly the id. Anything docker writes to stderr on
    # a successful `run` therefore fails container creation, with an error that
    # blames parsing rather than naming the warning.
    it "finds the id when docker pulled the image and logged progress to stderr" do
      expect(helper.parse_container_id(DockerOutput::RUN_WITH_PULL_ON_STDERR))
        .to eq DockerOutput::RUN_CONTAINER_ID
    end

    it "finds the id when the kernel lacks swap accounting" do
      expect(helper.parse_container_id(DockerOutput::RUN_WITH_SWAP_WARNING))
        .to eq DockerOutput::RUN_CONTAINER_ID
    end
  end

  describe "#remote_socket? and #socket_uri" do
    {
      "unix:///var/run/docker.sock" => false,
      "npipe:////./pipe/docker_engine" => false,
      "tcp://docker.example.com:2376" => true,
      "tcp://127.0.0.1:2375" => true,
    }.each do |socket, remote|
      it "treats #{socket} as #{remote ? "remote" : "local"}" do
        expect(helper(socket: socket).remote_socket?).to eq remote
      end
    end

    it "reports a socket-less configuration as local" do
      expect(helper(socket: nil).remote_socket?).to be false
    end

    it "exposes the socket as a URI" do
      expect(helper(socket: "tcp://docker.example.com:2376").socket_uri.port).to eq 2376
    end
  end

  describe "#dockerfile_proxy_config" do
    it "is empty when no proxy is configured" do
      expect(helper.dockerfile_proxy_config).to eq ""
    end

    # Tools inside the image disagree about the spelling, so both cases have to
    # be set. Dropping either half breaks builds behind a proxy in a way that
    # only shows up on somebody else's network.
    {
      http_proxy: %w{http_proxy HTTP_PROXY},
      https_proxy: %w{https_proxy HTTPS_PROXY},
      no_proxy: %w{no_proxy NO_PROXY},
    }.each do |option, spellings|
      it "sets #{spellings.join(" and ")} for #{option}" do
        lines = helper(option => "http://proxy:8080").dockerfile_proxy_config.lines.map(&:strip)
        spellings.each { |name| expect(lines).to include "ENV #{name}=http://proxy:8080" }
      end
    end

    it "emits only the proxies that are configured" do
      config = helper(http_proxy: "http://proxy:8080").dockerfile_proxy_config
      expect(config).not_to match(/no_proxy|https_proxy/i)
    end
  end

  describe "#container_env_variables" do
    def with_printenv(output)
      h = helper
      allow(h).to receive(:docker_command).and_return(output)
      h.container_env_variables(platform: "ubuntu-24.04")
    end

    it "reads the container's environment" do
      expect(with_printenv("HOME=/root\nUSER=kitchen\n"))
        .to eq("HOME" => "/root", "USER" => "kitchen")
    end

    # printenv output is `NAME=VALUE`, and values routinely contain `=`:
    # LS_COLORS and any JAVA_OPTS-style variable do. Splitting on every `=`
    # rather than the first silently truncates them, and the truncated value
    # then flows into replace_env_variables and into upload paths.
    it "keeps a value containing an equals sign intact" do
      expect(with_printenv("LS_COLORS=rs=0:di=01;34\n"))
        .to eq("LS_COLORS" => "rs=0:di=01;34")
    end

    it "keeps a value that is itself a key=value list" do
      expect(with_printenv("JAVA_OPTS=-Dfoo=bar -Dbaz=qux\n"))
        .to eq("JAVA_OPTS" => "-Dfoo=bar -Dbaz=qux")
    end

    it "keeps a variable with an empty value" do
      expect(with_printenv("EMPTY=\n")).to eq("EMPTY" => "")
    end

    it "ignores a continuation line of a multi-line value" do
      # printenv prints an embedded newline literally, so the second line has no
      # name. Recording it would put a nil-valued entry under a bogus key.
      expect(with_printenv("CERT=-----BEGIN-----\nMIIBIjANBg\n"))
        .to eq("CERT" => "-----BEGIN-----")
    end

    it "parses the JSON a Windows container returns" do
      h = helper
      allow(h).to receive(:docker_command).and_return('{"TEMP":"C:\\\\Users\\\\ADMINI~1\\\\AppData\\\\Local\\\\Temp"}')
      expect(h.container_env_variables(platform: "windows-2022"))
        .to eq("TEMP" => 'C:\Users\ADMINI~1\AppData\Local\Temp')
    end
  end

  describe "#replace_env_variables" do
    let(:linux_state) { { platform: "ubuntu-24.04", container_id: "abc" } }
    let(:windows_state) { { platform: "windows-2022", container_id: "abc" } }

    def helper_returning(vars)
      h = helper
      allow(h).to receive(:container_env_variables).and_return(vars)
      h
    end

    it "expands a POSIX $VAR reference" do
      h = helper_returning("TEMP" => "/var/tmp")
      expect(h.replace_env_variables(linux_state, "$TEMP/kitchen")).to eq "/var/tmp/kitchen"
    end

    it "expands a PowerShell $env:VAR reference" do
      h = helper_returning("TEMP" => 'C:\Temp')
      expect(h.replace_env_variables(windows_state, '$env:TEMP\kitchen')).to eq 'C:\Temp\kitchen'
    end

    it "leaves a path with no variable reference alone" do
      expect(helper.replace_env_variables(linux_state, "/tmp/kitchen")).to eq "/tmp/kitchen"
    end

    it "substitutes an empty string when the variable is not set in the container" do
      # Documents current behaviour rather than endorsing it: an unset variable
      # silently yields a path like "/kitchen" instead of failing, and the
      # upload then lands somewhere unexpected.
      h = helper_returning({})
      expect(h.replace_env_variables(linux_state, "$TEMP/kitchen")).to eq "/kitchen"
    end
  end

  describe "#container_exists? and #container_running?" do
    # `docker inspect` answers for a container in any state; `docker top` only
    # for a running one. The two predicates have to disagree on a stopped
    # container, or destroy cannot clean it up.
    def helper_answering(inspect_ok:, running: "false")
      h = helper
      allow(h).to receive(:docker_command) do |cmd, _opts = {}|
        raise Kitchen::ShellOut::ShellCommandFailed, "No such container" unless inspect_ok

        cmd.include?("{{.State.Running}}") ? "#{running}\n" : "[{...}]"
      end
      h
    end

    let(:state) { { container_id: "abc123abc123" } }

    it "reports a running container as existing and running" do
      h = helper_answering(inspect_ok: true, running: "true")
      expect(h.container_exists?(state)).to be true
      expect(h.container_running?(state)).to be true
    end

    it "reports a stopped container as existing but not running" do
      h = helper_answering(inspect_ok: true, running: "false")
      expect(h.container_exists?(state)).to be true
      expect(h.container_running?(state)).to be false
    end

    it "reports a container docker does not know as neither" do
      h = helper_answering(inspect_ok: false)
      expect(h.container_exists?(state)).to be false
      expect(h.container_running?(state)).to be false
    end

    it "reports no container when state names none" do
      h = helper
      expect(h).not_to receive(:docker_command)
      expect(h.container_exists?({})).to be false
      expect(h.container_running?({})).to be false
    end

    it "asks docker about a container, not about its processes" do
      # `docker top` was the original implementation and is the bug: it fails
      # on a stopped container, which read as the container not existing.
      h = helper
      seen = []
      allow(h).to receive(:docker_command) { |cmd, _opts = {}| seen << cmd; "[{...}]" }
      h.container_exists?(state)
      expect(seen.join).to include("inspect --type=container")
      expect(seen.join).not_to include("top ")
    end
  end

  describe "#container_ip_address" do
    def helper_inspecting(output)
      h = helper
      @asked = nil
      allow(h).to receive(:docker_command) { |cmd, _opts = {}| @asked = cmd; output }
      h
    end

    let(:state) { { container_id: "abc123abc123" } }

    it "returns the address docker reports" do
      expect(helper_inspecting("172.17.0.7 \n").container_ip_address(state)).to eq "172.17.0.7"
    end

    it "reads Networks rather than the removed top-level IPAddress" do
      # Docker 29 dropped NetworkSettings.IPAddress. Asking for it does not
      # return empty -- it fails the whole inspect with a template error, which
      # took use_internal_docker_network down with it.
      helper_inspecting("172.17.0.7\n").container_ip_address(state)
      expect(@asked).to include(".NetworkSettings.Networks")
      expect(@asked).not_to include(".NetworkSettings.IPAddress")
    end

    it "takes the first address when the container is on several networks" do
      expect(helper_inspecting("172.17.0.7 172.19.0.2 \n").container_ip_address(state))
        .to eq "172.17.0.7"
    end

    it "handles an IPv6 address" do
      expect(helper_inspecting("2001:db8::2 \n").container_ip_address(state)).to eq "2001:db8::2"
    end

    it "ignores a warning docker wrote to stderr" do
      expect(helper_inspecting("WARNING: something happened\n172.17.0.7 \n").container_ip_address(state))
        .to eq "172.17.0.7"
    end

    it "fails loudly when docker reports no address" do
      # Returning "" here would be recorded as the instance hostname, and the
      # connection would fail somewhere far from the cause.
      expect { helper_inspecting(" \n").container_ip_address(state) }
        .to raise_error(Kitchen::ActionFailed, /no IP address/)
    end

    it "fails loudly when the inspect itself fails" do
      h = helper
      allow(h).to receive(:docker_command).and_raise(Kitchen::ShellOut::ShellCommandFailed, "boom")
      expect { h.container_ip_address(state) }
        .to raise_error(Kitchen::ActionFailed, /Error getting internal IP/)
    end
  end

  describe "#remove_container" do
    it "stops the container before removing it" do
      # `docker rm` refuses to remove a running container, so the order matters.
      h = helper
      calls = []
      allow(h).to receive(:docker_command) { |cmd| calls << cmd }
      h.remove_container(container_id: "abc")
      expect(calls).to eq ["stop -t 0 abc", "rm abc"]
    end
  end

  describe "#copy_file_to_container" do
    let(:state) { { container_id: "abc", platform: "ubuntu-24.04" } }

    # Records every docker subcommand, and answers the copy check with
    # `landed`. `docker cp` itself prints nothing on success, so the probe is
    # the only call whose output matters.
    def copier(landed:)
      helper.tap do |h|
        @commands = []
        allow(h).to receive(:replace_env_variables) { |_s, path| path }
        allow(h).to receive(:docker_command) do |cmd, _opts = {}|
          @commands << cmd
          cmd.include?(described_class::COPIED_MARKER) && landed ? "#{described_class::COPIED_MARKER}\n" : ""
        end
      end
    end

    it "addresses the destination as container:path" do
      copier(landed: true).copy_file_to_container(state, "/local/f.rb", "/tmp/f.rb")
      expect(@commands.first).to eq "cp /local/f.rb abc:/tmp/f.rb"
    end

    it "says nothing when the file arrived" do
      expect { copier(landed: true).copy_file_to_container(state, "/local/f.rb", "/tmp/f.rb") }
        .not_to raise_error
    end

    # From #387. `docker cp` writes to the container's filesystem layer, which
    # a tmpfs or volume mounted over the destination then hides -- and it exits
    # 0, so nothing about the copy says it did not happen. Left unchecked the
    # first sign is the next command failing with "No such file or directory",
    # which names neither the copy nor the mount.
    context "when docker exits 0 but wrote nothing, as it does into a mount" do
      it "fails at the copy rather than somewhere later" do
        expect { copier(landed: false).copy_file_to_container(state, "/local/f.rb", "/tmp/f.rb") }
          .to raise_error(RuntimeError, %r{Failed to copy file /local/f\.rb})
      end

      it "names the mount as the cause" do
        expect { copier(landed: false).copy_file_to_container(state, "/local/f.rb", "/tmp/f.rb") }
          .to raise_error(RuntimeError, /cannot write into a mount/)
      end

      it "names the settings that move the destination off the mount" do
        expect { copier(landed: false).copy_file_to_container(state, "/local/f.rb", "/tmp/f.rb") }
          .to raise_error(RuntimeError, /temp_dir.*root_path/m)
      end
    end

    it "checks the path docker copies into, not the directory it was given" do
      copier(landed: true).copy_file_to_container(state, "/local/f.rb", "/tmp")
      # The probe is handed both parts and picks between them inside the
      # container, since only there is it known whether /tmp is a directory.
      expect(@commands.last).to include("/tmp f.rb")
    end

    it "does not print the probe's marker to the console" do
      h = copier(landed: true)
      allow(h).to receive(:logger).and_return(double(debug?: false, debug: nil))
      opts = []
      allow(h).to receive(:docker_command) { |_cmd, o = {}| opts << o; "" }
      begin
        h.copy_file_to_container(state, "/local/f.rb", "/tmp/f.rb")
      rescue RuntimeError
        nil
      end
      expect(opts.last).to eq(suppress_output: true)
    end

    # Windows containers have no tmpfs, and `docker cp` against them is a
    # different code path in Docker, so they keep the behaviour they had.
    it "does not probe a Windows container" do
      h = copier(landed: false)
      h.copy_file_to_container({ container_id: "abc", platform: "windows-2022" }, "C:\\f.rb", "C:\\Temp")
      expect(@commands.length).to eq 1
    end
  end
end
