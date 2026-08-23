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

    it "does not mistake a hex-looking word inside a message for an id" do
      # The id has to be the whole line. A warning that happens to contain a
      # twelve-character hex word must not be read as a container id, or the
      # driver would track a container that does not exist.
      expect { helper.parse_container_id("WARNING: layer abcdef123456 was skipped\n") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker run output/)
    end

    it "takes the id docker printed, not a later line" do
      expect(helper.parse_container_id(DockerOutput::RUN_WITH_PULL_ON_STDERR))
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
      pending "BUG: values are split on every '=' rather than the first; use split(\"=\", 2)"
      expect(with_printenv("LS_COLORS=rs=0:di=01;34\n"))
        .to eq("LS_COLORS" => "rs=0:di=01;34")
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
    it "addresses the destination as container:path" do
      h = helper
      allow(h).to receive(:replace_env_variables) { |_state, path| path }
      expect(h).to receive(:docker_command).with("cp /local/f.rb abc:/tmp/f.rb")
      h.copy_file_to_container({ container_id: "abc", platform: "ubuntu-24.04" }, "/local/f.rb", "/tmp/f.rb")
    end
  end
end
