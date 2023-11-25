#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fileutils" unless defined?(FileUtils)

module Kitchen
  module Docker
    module Helpers
      module FileHelper
        def create_temp_file(file, contents)
          debug("[Docker] Creating temp file #{file}")
          debug("[Docker] --- Start Temp File Contents ---")
          debug(contents)
          debug("[Docker] --- End Temp File Contents ---")

          begin
            path = ::File.dirname(file)
            ::FileUtils.mkdir_p(path) unless ::Dir.exist?(path)
            file = ::File.open(file, "w")
            file.write(contents)
          rescue IOError => e
            raise "Failed to write temp file. Error Details: #{e}"
          ensure
            file.close unless file.nil?
          end
        end
      end
    end
  end
end
