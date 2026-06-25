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

# This helper patches kitchen-inspec and/or kitchen-cinc-auditor to add Docker
# transport support. Remove once upstream gems include this natively.

# Patch kitchen-inspec if available
begin
  require "kitchen/verifier/inspec"
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
rescue LoadError
  # kitchen-inspec not available; skipping patch
end

# Patch kitchen-cinc-auditor if available
begin
  require "kitchen/verifier/cinc_auditor"
  Kitchen::Verifier::CincAuditor::TransportOptions.class_eval do
    def build_docker(state)
      options = {
        "backend" => "docker",
        "logger" => logger,
        "host" => state[:container_id],
      }
      logger.debug("Connect to Container: #{options["host"]}")
      options
    end
  end
rescue LoadError
  # kitchen-cinc-auditor not available; skipping patch
end

module Kitchen
  module Docker
    module Helpers
      # Marker module included by the Docker transport Connection class.
      # Actual verifier patches are applied directly to verifier classes above.
      module InspecHelper
      end
    end
  end
end
