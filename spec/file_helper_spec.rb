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

describe Kitchen::Docker::Helpers::FileHelper do
  around do |example|
    Dir.mktmpdir { |dir| @dir = dir; example.run }
  end

  describe "#create_temp_file" do
    it "writes the contents" do
      path = File.join(@dir, "docker-abc.sh")
      helper.create_temp_file(path, "echo hi\n")
      expect(File.read(path)).to eq "echo hi\n"
    end

    it "creates the parent directory" do
      # Container#execute writes to ./.kitchen/temp, which does not exist on a
      # fresh checkout.
      path = File.join(@dir, ".kitchen", "temp", "docker-abc.sh")
      helper.create_temp_file(path, "echo hi\n")
      expect(File.read(path)).to eq "echo hi\n"
    end

    it "replaces the contents of an existing file" do
      path = File.join(@dir, "docker-abc.sh")
      File.write(path, "old and longer content")
      helper.create_temp_file(path, "new\n")
      expect(File.read(path)).to eq "new\n"
    end

    it "leaves no open handle behind" do
      path = File.join(@dir, "docker-abc.sh")
      before = ObjectSpace.each_object(File).count { |f| !f.closed? }
      helper.create_temp_file(path, "echo hi\n")
      expect(ObjectSpace.each_object(File).count { |f| !f.closed? }).to eq before
    end

    # Every one of these used to raise "undefined method 'close' for an instance
    # of String": the open failed, `file` was still the path, and the ensure
    # tried to close it. The real cause never reached the user, who saw a Ruby
    # NoMethodError reported as a Docker failure.
    context "when the file cannot be written" do
      it "reports a parent that is not a directory" do
        # ".kitchen" existing as a file rather than a directory. The exact errno
        # differs by platform -- macOS reports EEXIST from mkdir here, Linux
        # ENOTDIR -- so the assertion is that the underlying cause reaches the
        # user at all, which is what used to be lost.
        blocker = File.join(@dir, "kitchen")
        File.write(blocker, "not a directory")
        path = File.join(blocker, "temp", "docker-abc.sh")

        expect { helper.create_temp_file(path, "echo hi") }
          .to raise_error(RuntimeError, /Failed to write temp file.*Error Details: \S+.*#{Regexp.escape(blocker)}/m)
      end

      it "reports a directory it may not write to" do
        readonly = File.join(@dir, "readonly")
        Dir.mkdir(readonly)
        File.chmod(0o500, readonly)

        begin
          expect { helper.create_temp_file(File.join(readonly, "docker-abc.sh"), "echo hi") }
            .to raise_error(RuntimeError, /Failed to write temp file.*Permission denied/m)
        ensure
          File.chmod(0o700, readonly)
        end
      end

      it "reports a target that is itself a directory" do
        target = File.join(@dir, "isadir")
        Dir.mkdir(target)

        expect { helper.create_temp_file(target, "echo hi") }
          .to raise_error(RuntimeError, /Failed to write temp file/)
      end

      it "names the path it could not write" do
        # The old message said only "Failed to write temp file", which did not
        # say which one.
        path = File.join(@dir, "isadir")
        Dir.mkdir(path)

        expect { helper.create_temp_file(path, "echo hi") }
          .to raise_error(RuntimeError, /#{Regexp.escape(path)}/)
      end

      it "never raises NoMethodError" do
        blocker = File.join(@dir, "kitchen")
        File.write(blocker, "not a directory")

        expect { helper.create_temp_file(File.join(blocker, "x.sh"), "echo hi") }
          .not_to raise_error(NoMethodError)
      end
    end
  end
end
