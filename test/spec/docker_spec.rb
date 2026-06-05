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

  describe "#parse_container_id" do
    subject { described_class.new.send(:parse_container_id, output) }

    # 64 hex chars (full id) and 12 hex chars (short id)
    let(:container_id) { "0123456789abcdef" * 4 }
    let(:short_id) { "abcdef123456" }

    # The warning Docker emits to stderr on rootless hosts. CliHelper#run_command
    # returns sh.stdout + sh.stderr, so this can be interleaved with the id.
    let(:warning) { "WARNING: IPv4 forwarding is disabled. Networking will not work." }

    context "with a bare 64-character container id" do
      let(:output) { container_id }
      it { is_expected.to eq(container_id) }
    end # /context with a bare 64-character container id

    context "with a bare 12-character short id" do
      let(:output) { short_id }
      it { is_expected.to eq(short_id) }
    end # /context with a bare 12-character short id

    context "with a trailing stderr warning after the container id" do
      let(:output) { "#{container_id}\n#{warning}\n" }
      it { is_expected.to eq(container_id) }
    end # /context with a trailing stderr warning after the container id

    context "with a leading stderr warning before the container id" do
      let(:output) { "#{warning}\n#{container_id}\n" }
      it { is_expected.to eq(container_id) }
    end # /context with a leading stderr warning before the container id

    context "with output containing no container id" do
      let(:output) { "#{warning}\nno container id here" }

      it "raises ActionFailed" do
        expect { subject }.to raise_error(Kitchen::ActionFailed, /Could not parse Docker run output/)
      end
    end # /context with output containing no container id
  end # /describe #parse_container_id
end
