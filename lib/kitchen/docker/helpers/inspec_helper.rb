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

# This helper should be removed when the kitchen-inspec gem has been updated to include these runner options
begin
  require "kitchen/verifier/inspec"

  # Add runner options for Docker transport for kitchen-inspec gem
  module Kitchen
    module Docker
      module Helpers
        module InspecHelper
          Kitchen::Verifier::Inspec.class_eval do
            def runner_options_for_docker(config_data)
              opts = {
                "backend" => "docker",
                "logger" => logger,
                "host" => config_data[:container_id],
              }
              logger.debug "Connect to Container: #{opts["host"]}"
              opts
            end
          end
        end
      end
    end
  end
rescue LoadError => e
  logger.debug("[Docker] kitchen-inspec gem not found for InSpec verifier. #{e}")
end
