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

describe Kitchen::Docker::ERBContext do
  def render(template, config)
    ERB.new(template).result(described_class.new(config).get_binding)
  end

  # A user-supplied `dockerfile:` is rendered through ERB with the driver
  # configuration exposed as instance variables. That is a documented part of
  # the driver's interface -- test/Dockerfile depends on it -- so the exposure
  # rules are worth pinning.
  it "exposes each configuration key as an instance variable" do
    expect(render("<%= @image %>", image: "ubuntu:24.04")).to eq "ubuntu:24.04"
  end

  it "exposes keys the driver has no option for" do
    # kitchen.yml's dockerfile platform passes `password`, which the driver
    # itself never reads; the template is the only consumer.
    expect(render("<%= @password %>", password: "secret")).to eq "secret"
  end

  it "renders a missing key as empty rather than failing the build" do
    expect(render("[<%= @nope %>]", {})).to eq "[]"
  end

  it "accepts string keys as well as symbols" do
    expect(render("<%= @image %>", "image" => "alpine")).to eq "alpine"
  end

  it "allows a template to read a file, as test/Dockerfile does with the public key" do
    Dir.mktmpdir do |dir|
      key = File.join(dir, "k.pub")
      File.write(key, "ssh-rsa AAAA test\n")
      expect(render("<%= IO.read(@public_key).strip %>", public_key: key))
        .to eq "ssh-rsa AAAA test"
    end
  end

  it "keeps values verbatim, without escaping" do
    # The template author decides on quoting; silently escaping here would
    # corrupt Dockerfiles that already quote correctly.
    expect(render("<%= @run_command %>", run_command: 'sshd -o "UseDNS=no"'))
      .to eq 'sshd -o "UseDNS=no"'
  end
end
