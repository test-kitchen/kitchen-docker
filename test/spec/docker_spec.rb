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

require 'spec_helper'

describe Kitchen::Driver::Docker do
  describe '#config_to_options' do
    let(:config) { }
    subject { described_class.new.send(:config_to_options, config) }

    context 'with nil' do
      let(:config) { nil }
      it { is_expected.to eq '' }
    end # /context with nil

    context 'with a string' do
      let(:config) { '--foo' }
      it { is_expected.to eq '--foo' }
    end # /context with a string

    context 'with a string with spaces' do
      let(:config) { '--foo bar' }
      it { is_expected.to eq '--foo bar' }
    end # /context with a string with spaces

    context 'with an array of strings' do
      let(:config) { %w{--foo --bar} }
      it { is_expected.to eq '--foo --bar' }
    end # /context with an array of strings

    context 'with an array of hashes' do
      let(:config) { [{foo: 'bar'}, {other: 'baz'}] }
      it { is_expected.to eq '--foo=bar --other=baz' }
    end # /context with an array of hashes

    context 'with a hash of strings' do
      let(:config) { {foo: 'bar', other: 'baz'} }
      it { is_expected.to eq '--foo=bar --other=baz' }
    end # /context with a hash of strings

    context 'with a hash of arrays' do
      let(:config) { {foo: %w{bar baz}} }
      it { is_expected.to eq '--foo=bar --foo=baz' }
    end # /context with a hash of arrays

    context 'with a hash of strings with spaces' do
      let(:config) { {foo: 'bar two', other: 'baz'} }
      it { is_expected.to eq '--foo=bar\\ two --other=baz' }
    end # /context with a hash of strings with spaces
  end # /describe #config_to_options
end
