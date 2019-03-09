#
# Copyright 2019, Rene Martin
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

describe Kitchen::Transport::Docker do
  let(:config) { {} }
  let(:state) { {} }
  let(:transport) { ::Kitchen::Transport::Docker.new(config) }
  let(:connection) { transport.connection(state) }
  let(:container) { double }

  describe '#connection' do
    context 'Default context' do
      it 'returns an instance of Kitchen::Transport::Docker::Connection' do
        conn = transport.connection({})
        expect(conn).to be_an_instance_of(Kitchen::Transport::Docker::Connection)
      end
    end

    context '#execute' do
      it 'Creates a connection to the docker service' do
        docker_con = double
        allow(::Docker::Connection).to receive(:new).and_return docker_con
        expect(connection.docker_connection).to eq docker_con
      end

      it 'Returns same connection when called the second time' do
        docker_con = double
        allow(::Docker::Connection).to receive(:new).and_return docker_con
        expect(connection.docker_connection).to eq docker_con
        allow(::Docker::Connection).to receive(:new).and_raise('Error!!!!')
        expect(connection.docker_connection).to eq docker_con
      end

      it 'Applies the right configuration' do
        expect(true).to eq true
      end
    end

    context '#execute' do
      let(:state) { {:container_id => 'container_sha' } }

      it 'does nothing when there is no command' do
        result = connection.execute(nil)
        expect(result).to be nil
        expect(::Docker::Container).not_to receive(:get)
      end

      it 'Runs a sh shell in the container to run the command' do
        allow(::Docker::Container).to receive(:get).with('container_sha', {}, anything).and_return container
        expect(container).to receive(:exec).with(['/bin/sh', '-c', 'ls -l /'], wait: 600, 'e' => { 'TERM' => 'xterm' }).and_return([nil, nil, 0])
        connection.execute('ls -l /')
      end


      it 'Raise a TransportFailed execption if the command errors out' do
        allow(::Docker::Container).to receive(:get).with('container_sha', {}, anything).and_return container
        expect(container).to receive(:exec).with(['/bin/sh', '-c', 'ls -l /non_existing_folder'], wait: 600, 'e' => { 'TERM' => 'xterm' }).and_return([nil, nil, 255])
        expect { connection.execute('ls -l /non_existing_folder') }.to raise_error(::Kitchen::Transport::TransportFailed)
      end
    end

    context '#execute shell override' do
      let(:state) { {:container_id => 'container_sha' } }
      let(:config) { {:shell => '/bin/bash'} }
      it 'Runs a bash shell when the default value is overriten' do
        allow(::Docker::Container).to receive(:get).with('container_sha', {}, anything).and_return container
        allow(container).to receive(:exec).with(['/bin/bash', '-c', 'ls -l /'], wait: 600, 'e' => { 'TERM' => 'xterm' }).and_return([nil, nil, 0])
        connection.execute('ls -l /')
      end
    end

    context '#upload' do
      let(:state) { {:container_id => 'container_sha' } }

      before do
        allow(::Docker::Container).to receive(:get).with('container_sha', {}, anything).and_return container
        allow(::File).to receive(:directory?).and_call_original
      end

      it 'Uploads a file' do
        allow(::File).to receive(:directory?).with('file.txt').and_return false
        expect(container).to receive(:archive_in).with(['file.txt'], '/tmp/kitchen/file.txt')
        connection.upload(['file.txt'], '/tmp/kitchen/file.txt')
      end

      it 'Uploads a directory' do
        allow(::File).to receive(:directory?).with('dir1').and_return true
        tarball = double
        expect(::Docker::Util).to receive(:create_dir_tar).with('dir1').and_return tarball
        expect(container).to receive(:exec).with(['mkdir', '/tmp/kitchen/dir1'])
        expect(container).to receive(:archive_in_stream).with('/tmp/kitchen/dir1', overwrite: true)
        connection.upload(['dir1'], '/tmp/kitchen/')
      end
    end

    context '#login_command' do
      let(:state) { {:container_id => 'container_sha' } }
      it 'Returns a nice docker login command' do
        expect(Kitchen::LoginCommand).to receive(:new)
          .with('docker', ['exec', '-e', "COLUMNS=#{`tput cols`}", '-e', "LINES=#{`tput lines`}", '-it', 'container_sha', '/bin/sh', '-login', '-i'])
          .and_call_original
        cmd = connection.login_command
        expect(cmd).to be_an_instance_of(::Kitchen::LoginCommand)
      end
    end
  end
end
