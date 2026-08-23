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

describe Kitchen::Docker::Helpers::CliHelper do
  let(:image_id) { "sha256:abc123" }

  # Assertions are made against the argument vector a shell would produce, not
  # against the command string. See spec/support/argv.rb for why.
  def run_argv(config = {})
    argv(helper(config.merge(run_command: "/usr/sbin/sshd -D")).build_run_command(image_id))
  end

  describe "#build_run_command" do
    describe "the baseline command" do
      it "runs the image detached, with the configured run command" do
        expect(run_argv).to eq ["run", "-d", image_id, "/usr/sbin/sshd", "-D"]
      end

      it "adds nothing that was not configured" do
        # A flag leaking in when its option is unset is a silent behaviour
        # change for every user; pinning the empty case catches it.
        expect(run_argv.length).to eq 5
      end
    end

    # Each entry pairs a configuration with the arguments Docker must receive.
    # A dropped or misspelled flag is the failure mode this table exists for:
    # the option is accepted in kitchen.yml, nothing happens, and nothing warns.
    {
      "privileged" => [{ privileged: true }, %w{--privileged}],
      "publish_all" => [{ publish_all: true }, %w{-P}],
      "interactive" => [{ interactive: true }, %w{-i}],
      "tty" => [{ tty: true }, %w{-t}],
      "hostname" => [{ hostname: "web.local" }, %w{-h web.local}],
      "memory" => [{ memory: "512m" }, %w{-m 512m}],
      "cpu" => [{ cpu: "512" }, %w{-c 512}],
      "gpus" => [{ gpus: "all" }, %w{--gpus all}],
      "isolation" => [{ isolation: "hyperv" }, %w{--isolation hyperv}],
      "instance_name" => [{ instance_name: "web" }, %w{--name web}],
      "forward" => [{ forward: "80:8080" }, %w{-p 80:8080}],
      "dns" => [{ dns: "8.8.8.8" }, %w{--dns 8.8.8.8}],
      "volume" => [{ volume: "/ftp:/ftp" }, %w{-v /ftp:/ftp}],
      "volumes_from" => [{ volumes_from: "repos" }, %w{--volumes-from repos}],
      "links" => [{ links: "db:db" }, %w{--link db:db}],
      "devices" => [{ devices: "/dev/vboxdrv" }, %w{--device /dev/vboxdrv}],
      "tmpfs" => [{ tmpfs: "/tmp" }, %w{--tmpfs /tmp}],
      "mount" => [{ mount: "type=tmpfs,destination=/run" }, %w{--mount type=tmpfs,destination=/run}],
      "add_host" => [{ add_host: { "db" => "10.0.0.5" } }, %w{--add-host=db:10.0.0.5}],
      "cap_add" => [{ cap_add: "SYS_PTRACE" }, %w{--cap-add=SYS_PTRACE}],
      "cap_drop" => [{ cap_drop: "CHOWN" }, %w{--cap-drop=CHOWN}],
      "security_opt" => [{ security_opt: "apparmor:my_profile" }, %w{--security-opt=apparmor:my_profile}],
      "docker_platform" => [{ docker_platform: "linux/arm64" }, %w{--platform=linux/arm64}],
      "http_proxy" => [{ http_proxy: "http://p:8080" }, %w{-e http_proxy=http://p:8080}],
      "https_proxy" => [{ https_proxy: "http://p:8080" }, %w{-e https_proxy=http://p:8080}],
    }.each do |option, (config, expected)|
      it "passes #{option} through as #{expected.join(" ")}" do
        expect(run_argv(config)).to include_consecutive(*expected)
      end
    end

    describe "options documented as accepting one value or a list" do
      # README tells users these take either form. Array() is what makes that
      # true, and it is easy to drop when an option is edited.
      %i{forward dns volume volumes_from links devices tmpfs mount cap_add cap_drop security_opt}.each do |option|
        it "accepts a bare value for #{option}" do
          expect { run_argv(option => "one") }.not_to raise_error
        end

        it "emits one argument group per entry for #{option}" do
          many = run_argv(option => %w{one two})
          expect(many.grep(/one/)).not_to be_empty
          expect(many.grep(/two/)).not_to be_empty
        end
      end
    end

    describe "the transport port" do
      it "publishes the port the transport asks for" do
        cmd = helper({ run_command: "sshd" }).build_run_command(image_id, 2222)
        expect(argv(cmd)).to include_consecutive("-p", "2222")
      end

      it "publishes nothing when the transport asks for no port" do
        cmd = helper({ run_command: "sshd" }).build_run_command(image_id, nil)
        expect(argv(cmd)).not_to include "-p"
      end
    end

    describe "quoting" do
      # Docker command lines are built as strings and handed to a shell, so a
      # configured value containing a space has to survive shell splitting as a
      # single argument. These are the cases where it does not.
      it "keeps a volume path containing a space as one argument" do
        expect(run_argv(volume: "/host dir:/data")).to include_consecutive("-v", "/host dir:/data")
      end

      it "keeps a hostname containing a space as one argument" do
        expect(run_argv(hostname: "two words")).to include_consecutive("-h", "two words")
      end

      it "keeps a mount specification containing a space as one argument" do
        expect(run_argv(mount: "type=bind,source=/my dir,destination=/d"))
          .to include_consecutive("--mount", "type=bind,source=/my dir,destination=/d")
      end
    end
  end

  describe "#build_exec_command" do
    let(:state) { { container_id: "abc123" } }

    def exec_argv(config = {}, command: "whoami")
      argv(helper(config).build_exec_command(state, command))
    end

    it "execs the command in the container" do
      expect(exec_argv).to eq %w{exec abc123 whoami}
    end

    {
      "detach" => [{ detach: true }, %w{-d}],
      "privileged" => [{ privileged: true }, %w{--privileged}],
      "tty" => [{ tty: true }, %w{-t}],
      "interactive" => [{ interactive: true }, %w{-i}],
      "username" => [{ username: "kitchen" }, %w{-u kitchen}],
      "working_dir" => [{ working_dir: "/srv" }, %w{-w /srv}],
    }.each do |option, (config, expected)|
      it "passes #{option} through as #{expected.join(" ")}" do
        expect(exec_argv(config)).to include_consecutive(*expected)
      end
    end

    it "puts the container id before the command" do
      # Reversing these makes Docker try to exec into the command name, with an
      # error that does not point anywhere near the cause.
      result = exec_argv({ username: "kitchen" }, command: "whoami")
      expect(result.index("abc123")).to be < result.index("whoami")
    end
  end

  describe "#build_env_variable_args" do
    it "emits one -e flag per variable" do
      expect(argv(helper.build_env_variable_args("A" => "1", "B" => "2")))
        .to eq %w{-e A=1 -e B=2}
    end

    it "strips surrounding whitespace from names and values" do
      expect(argv(helper.build_env_variable_args(" A " => " 1 "))).to eq %w{-e A=1}
    end

    it "refuses anything that is not a Hash" do
      # The driver would otherwise build "-e" flags out of an Array's elements
      # and produce a command line that fails somewhere far from the cause.
      expect { helper.build_env_variable_args(%w{A=1}) }
        .to raise_error(Kitchen::ActionFailed, /not of a Hash type/)
    end

    it "keeps a value containing a space as one argument" do
      expect(argv(helper.build_env_variable_args("MSG" => "hello world")))
        .to eq ["-e", "MSG=hello world"]
    end

    it "keeps a value containing a double quote intact" do
      expect(argv(helper.build_env_variable_args("MSG" => 'say "hi"')))
        .to eq ["-e", 'MSG=say "hi"']
    end

    it "keeps a value containing a dollar sign out of the shell's reach" do
      # An unescaped $HOME would be expanded by the shell running the docker
      # command, so the container would receive the workstation's home
      # directory instead of the literal string.
      expect(argv(helper.build_env_variable_args("P" => "$HOME/x")))
        .to eq ["-e", "P=$HOME/x"]
    end

    it "keeps a name containing a space as one argument" do
      expect(argv(helper.build_env_variable_args("ODD NAME" => "v")))
        .to eq ["-e", "ODD NAME=v"]
    end
  end

  describe "#build_copy_command" do
    it "copies local to remote" do
      expect(argv(helper.build_copy_command("/tmp/a", "abc:/tmp/a")))
        .to eq %w{cp /tmp/a abc:/tmp/a}
    end

    it "preserves ownership and mode when asked" do
      expect(argv(helper.build_copy_command("/tmp/a", "abc:/tmp/a", archive: true)))
        .to eq %w{cp -a /tmp/a abc:/tmp/a}
    end

    it "keeps a local path containing a space as one argument" do
      expect(argv(helper.build_copy_command("/Users/me/My Cookbooks/f.rb", "abc:/tmp/f.rb")))
        .to eq ["cp", "/Users/me/My Cookbooks/f.rb", "abc:/tmp/f.rb"]
    end
  end

  describe "#config_to_options" do
    subject { helper.config_to_options(input) }

    context "with nil" do
      let(:input) { nil }

      it { is_expected.to eq "" }
    end

    context "with a string" do
      let(:input) { "--foo" }

      it { is_expected.to eq "--foo" }
    end

    context "with a string with spaces" do
      let(:input) { "--foo bar" }

      it { is_expected.to eq "--foo bar" }
    end

    context "with an array of strings" do
      let(:input) { %w{--foo --bar} }

      it { is_expected.to eq "--foo --bar" }
    end

    context "with an array of hashes" do
      let(:input) { [{ foo: "bar" }, { other: "baz" }] }

      it { is_expected.to eq "--foo=bar --other=baz" }
    end

    context "with a hash of strings" do
      let(:input) { { foo: "bar", other: "baz" } }

      it { is_expected.to eq "--foo=bar --other=baz" }
    end

    context "with a hash of arrays" do
      let(:input) { { foo: %w{bar baz} } }

      it { is_expected.to eq "--foo=bar --foo=baz" }
    end

    context "with a hash of strings with spaces" do
      let(:input) { { foo: "bar two", other: "baz" } }

      it { is_expected.to eq '--foo=bar\\ two --other=baz' }

      it "survives shell splitting as one argument per flag" do
        expect(argv(subject)).to eq ["--foo=bar two", "--other=baz"]
      end
    end

    context "with a boolean value, as the README's build_options example uses" do
      let(:input) { { rm: false } }

      it { is_expected.to eq "--rm=false" }
    end
  end

  describe "#run_command" do
    it "returns stdout and stderr together" do
      # docker writes build progress and image ids to stderr, so the driver
      # reimplements run_command specifically to keep both streams.
      expect(helper.run_command("echo out; echo err 1>&2")).to eq "out\nerr\n"
    end

    it "raises Kitchen::ShellOut::ShellCommandFailed when the command fails" do
      # cli_helper raises a bare `ShellCommandFailed`, which resolves through
      # the included Kitchen::ShellOut rather than being spelled out. Pin the
      # class so a change to those includes cannot silently alter what callers
      # have to rescue.
      expect { helper.run_command("exit 7") }
        .to raise_error(Kitchen::ShellOut::ShellCommandFailed, /exit with \[0\], but received '7'/)
    end

    it "prefixes the command with the sudo command when use_sudo is set" do
      # Uses `echo` as the sudo command so the prefixing is observable without
      # needing real sudo on the machine running the specs.
      expect(helper.run_command("echo hi", use_sudo: true, sudo_command: "echo SUDO"))
        .to eq "SUDO echo hi\n"
    end

    it "does not prefix anything when use_sudo is unset" do
      expect(helper.run_command("echo hi")).to eq "hi\n"
    end
  end

  describe "#docker_shell_opts" do
    it "translates suppress_output into silencing the live stream" do
      expect(helper.docker_shell_opts(suppress_output: true)).to eq(live_stream: nil)
    end

    it "removes suppress_output, which Mixlib::ShellOut would reject" do
      expect(helper.docker_shell_opts(suppress_output: false)).not_to have_key(:suppress_output)
    end

    it "leaves other options alone" do
      expect(helper.docker_shell_opts(timeout: 60)).to eq(timeout: 60)
    end
  end

  describe "#dev_null" do
    it "returns a device that exists on this platform" do
      expect(helper.dev_null).to eq(Gem.win_platform? ? "NUL" : "/dev/null")
    end
  end
end
