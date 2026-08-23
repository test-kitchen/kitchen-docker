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
    # Mixins shared by the driver, transport, and container classes.
    module Helpers
      # Local temp-file handling.
      module FileHelper
        # Writes a temp file, creating its parent directory if needed.
        #
        # Written with +File.write+, which opens, writes and closes in one call.
        # The previous implementation assigned the open file back over the +file+
        # parameter and closed it in an +ensure+, so when opening failed -- a
        # read-only directory, a parent that is not a directory, a full disk --
        # +file+ was still the path String and the ensure raised
        # "undefined method 'close' for an instance of String", replacing the
        # real error with a Ruby one. Its rescue did not help either: it caught
        # +IOError+, while opening a file fails with +Errno+ classes, which are
        # +SystemCallError+ and not +IOError+.
        #
        # @param file [String] path to write
        # @param contents [String] what to write
        # @return [void]
        # @raise [RuntimeError] if the file cannot be written, naming the path
        #   and the underlying cause
        def create_temp_file(file, contents)
          debug("[Docker] Creating temp file #{file}")
          debug("[Docker] --- Start Temp File Contents ---")
          debug(contents)
          debug("[Docker] --- End Temp File Contents ---")

          path = ::File.dirname(file)
          ::FileUtils.mkdir_p(path) unless ::Dir.exist?(path)
          ::File.write(file, contents)
        rescue SystemCallError, IOError => e
          raise "Failed to write temp file #{file}. Error Details: #{e}"
        end
      end
    end
  end
end
