#
# Copyright (C) 2014, Sean Porter
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

require "erb" unless defined?(Erb)

module Kitchen
  module Docker
    # Evaluation context for a user-supplied Dockerfile template.
    #
    # Each configuration key becomes an instance variable, so a template can
    # refer to +@image+, +@username+, and the rest.
    class ERBContext
      # Exposes each config key to the template as an instance variable, so a
      # custom Dockerfile can refer to +@image+, +@username+, and the rest.
      #
      # @param config [Hash] the configuration to expose
      def initialize(config = {})
        config.each do |key, value|
          instance_variable_set("@" + key.to_s, value)
        end
      end

      # @return [Binding] a binding for ERB to evaluate the template in
      def get_binding
        binding
      end
    end
  end
end
