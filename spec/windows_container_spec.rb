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
require "tmpdir"

describe Kitchen::Docker::Container::Windows do
  def container(config = {})
    described_class.new({
      image: "mcr.microsoft.com/windows/servercore:ltsc2022",
      platform: "windows",
      username: "administrator",
    }.merge(config))
  end

  describe "#dockerfile" do
    subject(:dockerfile) { container.send(:dockerfile) }

    it "starts from the configured image" do
      expect(dockerfile.lines.first.strip).to eq "FROM mcr.microsoft.com/windows/servercore:ltsc2022"
    end

    it "installs no SSH server" do
      # Windows containers are driven entirely through `docker exec`. Emitting
      # the Linux SSH setup here would fail the build on the first RUN.
      expect(dockerfile).not_to match(/openssh|authorized_keys|sshd/)
    end

    it "appends each provision_command as its own RUN line" do
      expect(container(provision_command: ["powershell -Command a", "powershell -Command b"]).send(:dockerfile))
        .to include("RUN powershell -Command a\n").and include("RUN powershell -Command b\n")
    end

    it "carries the proxy configuration into the image" do
      expect(container(http_proxy: "http://proxy:8080").send(:dockerfile))
        .to include "ENV http_proxy=http://proxy:8080"
    end

    it "refuses to build for a non-Windows platform" do
      # Reaching here with platform: ubuntu means the driver picked the wrong
      # container class, and the resulting image would be silently wrong.
      expect { container(platform: "ubuntu").send(:dockerfile) }
        .to raise_error(Kitchen::ActionFailed, /Unknown platform 'ubuntu'/)
    end

    it "uses a custom dockerfile verbatim when configured" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "Dockerfile")
        File.write(path, "FROM <%= @image %>\n")
        expect(container(dockerfile: path).send(:dockerfile))
          .to eq "FROM mcr.microsoft.com/windows/servercore:ltsc2022\n"
      end
    end
  end

  describe "#execute" do
    def staged(config = {})
      c = container({ temp_dir: 'C:\\Temp' }.merge(config))
      allow(c).to receive(:create_dir_on_container)
      allow(c).to receive(:replace_env_variables) { |_cfg, path| path }
      allow(c).to receive(:upload)
      allow(c).to receive(:container_exec) { |_cfg, cmd| @ran = cmd }
      c
    end

    around do |example|
      Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
    end

    it "runs the staged script with powershell" do
      staged.execute("Write-Host hi")
      expect(@ran).to start_with "powershell -ExecutionPolicy Bypass -NoLogo "
      expect(@ran).to match(/-File .*docker-[0-9a-f-]+\.ps1/)
    end

    it "stages the script under the configured temp_dir" do
      staged.execute("Write-Host hi")
      expect(@ran).to include 'C:\\Temp\\docker-'
    end

    it "accepts a temp_dir written with forward slashes" do
      # Kitchen configuration is YAML that is often shared with Linux suites,
      # so the separator is normalised rather than rejected.
      staged(temp_dir: "C:/Temp").execute("Write-Host hi")
      expect(@ran).to include 'C:\\Temp\\docker-'
    end

    # A Windows temp_dir routinely contains a space -- $env:TEMP under a user
    # whose name has one does. PowerShell's -File takes exactly one argument,
    # so an unquoted path left it looking for a script named after the first
    # word.
    it "quotes a script path containing a space" do
      staged(temp_dir: 'C:\\Users\\Foo Bar\\Temp').execute("Write-Host hi")
      expect(@ran).to include('-File "C:\\Users\\Foo Bar\\Temp\\docker-').and end_with('.ps1"')
    end

    it "removes the staged script once the command has run" do
      staged.execute("Write-Host hi")
      expect(Dir.glob(".kitchen/temp/docker-*.ps1")).to be_empty
    end

    it "removes the staged script when the command fails" do
      c = staged
      allow(c).to receive(:container_exec).and_raise("command exploded")
      expect { c.execute("Write-Host hi") }.to raise_error(/Failed to execute command/)
      expect(Dir.glob(".kitchen/temp/docker-*.ps1")).to be_empty
    end
  end

  describe "the contract it shares with the Linux container" do
    # The two classes share almost no code but must agree on the state they
    # populate, because the driver and transport read the same keys whichever
    # one ran. A key added on one side and forgotten on the other shows up as a
    # nil far away from the cause.
    it "publishes no port, because there is no SSH server to reach" do
      c = container
      allow(c).to receive(:build_image).and_return("sha256:abc")
      allow(c).to receive(:container_exists?).and_return(false)
      allow(c).to receive(:hostname).and_return("localhost")
      expect(c).to receive(:run_container).with(anything).and_return("abc123")

      state = {}
      c.create(state)
      expect(state).not_to have_key(:port)
    end

    it "records the container id, image id, hostname, and username" do
      c = container
      allow(c).to receive(:build_image).and_return("sha256:abc")
      allow(c).to receive(:container_exists?).and_return(false)
      allow(c).to receive(:run_container).and_return("abc123")
      allow(c).to receive(:hostname).and_return("localhost")

      state = {}
      c.create(state)
      expect(state).to include(
        image_id: "sha256:abc",
        container_id: "abc123",
        hostname: "localhost",
        username: "administrator"
      )
    end
  end
end
