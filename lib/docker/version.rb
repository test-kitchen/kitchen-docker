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

begin
  require "docker"

  # Override API_VERSION constant in docker-api gem to use version 1.24 of the Docker API
  # This override is for the docker-api gem to communicate to the Docker engine on Windows
  module Docker
    VERSION = "0.0.0".freeze
    API_VERSION = "1.24".freeze
  end
rescue LoadError => e
  logger.debug("[Docker] docker-api gem not found for InSpec verifier. #{e}")
end
