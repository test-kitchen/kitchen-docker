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

describe Kitchen::Docker::Container::Linux do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      @public_key = File.join(dir, "docker_id_rsa.pub")
      File.write(@public_key, "ssh-rsa AAAAB3NzaC1yc2E kitchen_docker_key\n")
      example.run
    end
  end

  def container(config = {})
    described_class.new({
      image: "ubuntu:24.04",
      platform: "ubuntu",
      username: "kitchen",
      public_key: @public_key,
      private_key: File.join(@tmpdir, "docker_id_rsa"),
    }.merge(config))
  end

  # The state this populates is the whole contract with the rest of Test
  # Kitchen: the transport and the verifier read these keys, and a missing one
  # surfaces as a nil far from here.
  describe "#create" do
    def creating(config = {})
      c = container(config)
      allow(c).to receive(:container_exists?).and_return(false)
      allow(c).to receive(:build_image).and_return("sha256:abc")
      allow(c).to receive(:run_container).and_return("abc123abc123")
      allow(c).to receive(:hostname).and_return("localhost")
      allow(c).to receive(:docker_command).and_return("0.0.0.0:32768\n")
      c
    end

    it "records everything the transport needs to connect" do
      state = {}
      creating.create(state)
      expect(state).to include(
        image_id: "sha256:abc",
        container_id: "abc123abc123",
        hostname: "localhost",
        username: "kitchen",
        port: 32768
      )
    end

    it "records the key it generated, so SSH can use it" do
      state = {}
      creating.create(state)
      expect(state[:ssh_key]).to eq File.join(@tmpdir, "docker_id_rsa")
    end

    # 22 is the port inside the container; Docker publishes it on an arbitrary
    # host port, which is the one to connect to.
    it "publishes the SSH port" do
      c = creating
      expect(c).to receive(:run_container).with(anything, 22).and_return("abc123abc123")
      c.create({})
    end

    # Re-running create against an instance that is already up must not build a
    # second image or start a second container.
    it "reuses an image and container the state already names" do
      c = creating
      allow(c).to receive(:container_exists?).and_return(true)
      allow(c).to receive(:container_running?).and_return(true)
      expect(c).not_to receive(:build_image)
      expect(c).not_to receive(:run_container)
      c.create(image_id: "sha256:old", container_id: "old123old123")
    end
  end

  describe "#parse_container_ssh_port" do
    def port(output)
      container.send(:parse_container_ssh_port, output)
    end

    it "reads the published port from a dual-stack daemon" do
      expect(port(DockerOutput::PORT_DUAL_STACK)).to eq DockerOutput::PUBLISHED_PORT
    end

    it "reads the published port from an IPv4-only daemon" do
      expect(port(DockerOutput::PORT_IPV4_ONLY)).to eq DockerOutput::PUBLISHED_PORT
    end

    # `_host, port = output.split(":")` assumes the host is everything before
    # the first colon. On IPv6 output the first two fields are "[" and "", so
    # the port becomes "".to_i -- and `to_i` never raises, so the method's
    # rescue clause cannot fire. Test Kitchen is then handed port 0 and fails
    # far away from here, complaining that SSH was refused.
    it "reads the published port from an IPv6-only daemon" do
      expect(port(DockerOutput::PORT_IPV6_ONLY)).to eq DockerOutput::PUBLISHED_PORT
    end

    it "refuses to report a port it could not parse" do
      expect { port("") }.to raise_error(Kitchen::ActionFailed)
    end

    it "reads the published port when docker names the host" do
      expect(port("localhost:52239\n")).to eq DockerOutput::PUBLISHED_PORT
    end

    it "refuses to report a port from output with no port in it" do
      expect { port("no public port '22/tcp' published\n") }
        .to raise_error(Kitchen::ActionFailed, /Could not parse Docker port output/)
    end

    it "names the output it could not parse" do
      # The previous message said only that parsing failed, which left nobody
      # any way to tell what docker had actually printed.
      expect { port("surprising\n") }.to raise_error(Kitchen::ActionFailed, /surprising/)
    end

    it "never returns a port that cannot be connected to" do
      # The invariant behind both pending examples above: whatever this returns
      # has to be usable. Zero is not.
      expect(port(DockerOutput::PORT_DUAL_STACK)).to be_between(1, 65_535)
    end
  end

  describe "#container_ssh_port" do
    it "uses port 22 directly on the internal Docker network" do
      # On the Docker network the container is addressed by its own IP, so the
      # published mapping is irrelevant -- and asking for it would fail.
      c = container(use_internal_docker_network: true)
      expect(c).not_to receive(:docker_command)
      expect(c.send(:container_ssh_port, {})).to eq 22
    end

    it "raises a useful error when docker reports no mapping" do
      c = container
      allow(c).to receive(:docker_command).and_raise(StandardError, "no public port")
      expect { c.send(:container_ssh_port, container_id: "abc") }
        .to raise_error(Kitchen::ActionFailed, /no ssh port mapped/)
    end
  end

  describe "#dockerfile" do
    subject(:dockerfile) { container.send(:dockerfile) }

    it "starts from the configured image" do
      expect(dockerfile.lines.first.strip).to eq "FROM ubuntu:24.04"
    end

    it "authorises the generated public key" do
      # Without this line the container builds and starts, and then every
      # connection is refused -- the single most confusing way for this driver
      # to fail.
      expect(dockerfile).to match(%r{>> /home/kitchen/\.ssh/authorized_keys})
    end

    it "escapes the public key so a shell cannot split it" do
      # The key contains spaces, and it is appended with `RUN echo <key> >> ...`.
      run_line = dockerfile.lines.grep(/authorized_keys/).last
      expect(argv(run_line.sub(/\ARUN /, ""))).to include "ssh-rsa AAAAB3NzaC1yc2E kitchen_docker_key"
    end

    it "creates the login user" do
      expect(dockerfile).to match(/useradd .*kitchen/)
    end

    it "puts root's home in the right place" do
      expect(container(username: "root").send(:dockerfile)).to match(%r{>> /root/\.ssh/authorized_keys})
    end

    it "appends each provision_command as its own RUN line" do
      generated = container(provision_command: ["apt-get install -y dnsutils", "apt-get install -y telnet"])
        .send(:dockerfile)
      expect(generated).to include "RUN apt-get install -y dnsutils\n"
      expect(generated).to include "RUN apt-get install -y telnet\n"
    end

    it "accepts a single provision_command" do
      expect(container(provision_command: "echo hi").send(:dockerfile)).to include "RUN echo hi\n"
    end

    it "ends with a newline" do
      # A Dockerfile whose last line lacks a newline loses that instruction on
      # some builders.
      expect(dockerfile).to end_with "\n"
    end

    it "carries the proxy configuration into the image" do
      expect(container(http_proxy: "http://proxy:8080").send(:dockerfile))
        .to include "ENV http_proxy=http://proxy:8080"
    end

    context "when a custom dockerfile is configured" do
      it "uses it verbatim, rendered through ERB" do
        path = File.join(@tmpdir, "Dockerfile")
        File.write(path, "FROM <%= @image %>\nRUN echo <%= @username %>\n")
        expect(container(dockerfile: path).send(:dockerfile))
          .to eq "FROM ubuntu:24.04\nRUN echo kitchen\n"
      end

      it "does not append the generated SSH setup to it" do
        # The custom Dockerfile owns the whole image; silently appending would
        # overwrite what the author set up.
        path = File.join(@tmpdir, "Dockerfile")
        File.write(path, "FROM scratch\n")
        expect(container(dockerfile: path).send(:dockerfile)).not_to include "authorized_keys"
      end
    end
  end

  describe "#execute" do
    # The command is staged as a script under .kitchen/temp and uploaded. That
    # local copy has to go whether or not the rest of the run works, or a failing
    # converge leaves a file behind on every attempt.
    def container_in(dir, &upload)
      c = container
      allow(c).to receive(:create_dir_on_container)
      allow(c).to receive(:replace_env_variables) { |_cfg, path| path }
      allow(c).to receive(:container_exec).and_return("ok")
      allow(c).to receive(:upload, &(upload || ->(*) { nil }))
      allow(Dir).to receive(:pwd).and_return(dir)
      c
    end

    around do |example|
      Dir.chdir(@tmpdir) { example.run }
    end

    it "removes the staged script once the command has run" do
      c = container_in(@tmpdir)
      c.execute("echo hi")
      expect(Dir.glob(".kitchen/temp/docker-*.sh")).to be_empty
    end

    it "removes the staged script when the upload fails" do
      c = container_in(@tmpdir) { raise "upload exploded" }
      expect { c.execute("echo hi") }.to raise_error(/Failed to execute command/)
      expect(Dir.glob(".kitchen/temp/docker-*.sh")).to be_empty
    end

    it "removes the staged script when the command itself fails" do
      c = container_in(@tmpdir)
      allow(c).to receive(:container_exec).and_raise("command exploded")
      expect { c.execute("echo hi") }.to raise_error(/Failed to execute command/)
      expect(Dir.glob(".kitchen/temp/docker-*.sh")).to be_empty
    end

    it "uploads the command as the contents of the script" do
      uploaded = nil
      c = container_in(@tmpdir) { |local, _remote| uploaded = ::File.read(local) }
      c.execute("echo hi")
      expect(uploaded).to eq "echo hi"
    end
  end

  describe "#generate_keys" do
    it "writes a usable key pair when none exists" do
      private_key = File.join(@tmpdir, "generated")
      public_key = File.join(@tmpdir, "generated.pub")
      container(private_key: private_key, public_key: public_key).send(:generate_keys)

      expect(File.read(public_key)).to start_with "ssh-rsa "
      expect { OpenSSL::PKey::RSA.new(File.read(private_key)) }.not_to raise_error
    end

    it "leaves an existing key pair alone" do
      # Regenerating would invalidate the authorized_keys baked into images
      # that were already built.
      private_key = File.join(@tmpdir, "docker_id_rsa")
      File.write(private_key, "existing private key")
      before = File.read(@public_key)

      container(private_key: private_key).send(:generate_keys)

      expect(File.read(@public_key)).to eq before
      expect(File.read(private_key)).to eq "existing private key"
    end

    it "regenerates when only one half of the pair is present" do
      # A half-written pair cannot authenticate, so keeping it would strand the
      # user with a container they can never reach.
      File.delete(@public_key)
      private_key = File.join(@tmpdir, "docker_id_rsa")
      File.write(private_key, "orphaned private key")

      container(private_key: private_key).send(:generate_keys)

      expect(File.read(@public_key)).to start_with "ssh-rsa "
      expect(File.read(private_key)).not_to eq "orphaned private key"
    end
  end
end
