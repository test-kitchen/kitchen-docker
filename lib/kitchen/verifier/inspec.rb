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

module Kitchen
  module Verifier
    # This code is a temporary fix until the runner_options_for_docker method has been merged into the kitchen-inspec gem
    if Kitchen::Verifier::InSpec.respond_to?(:class_eval)
      Kitchen::Verifier::InSpec.class_eval do
        def runner_options_for_docker(config_data)
          opts = {
            'backend' => 'docker',
            'logger' => logger,
            'host' => config_data[:container_id],
          }
          logger.debug "Connect to Container: #{opts['host']}"
          opts
        end
      end
    else
      logger.debug('[InSpec] Unable to update InSpec verifier with Docker runner options.')
    end
  end
end
