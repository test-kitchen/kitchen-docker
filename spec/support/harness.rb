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

# Builds throwaway objects that mix in the driver's helper modules.
#
# The helpers are modules meant to be mixed into the driver, the transport, and
# the container classes. Testing them through one of those means dragging in a
# Test Kitchen instance, a platform, and a logger to exercise what is really
# just string building -- so mix them into a bare object with a config hash
# instead, which is what they actually depend on.
module HelperHarness
  # Every helper module, which is what the driver itself mixes in.
  ALL_HELPERS = [
    Kitchen::Docker::Helpers::CliHelper,
    Kitchen::Docker::Helpers::ContainerHelper,
    Kitchen::Docker::Helpers::DockerfileHelper,
    Kitchen::Docker::Helpers::ImageHelper,
    Kitchen::Docker::Helpers::FileHelper,
  ].freeze

  # Takes its configuration positionally rather than as keywords, so that
  # `helper(build_context: true)` cannot be mistaken for a keyword argument.
  #
  # @param config [Hash] driver configuration the helpers will read
  # @return [Object] an object responding to every helper method
  def helper(config = {})
    klass = Class.new do
      attr_accessor :config

      def initialize(config)
        @config = config
      end

      # Methods defined in the class body win over included modules regardless
      # of include order, so these override anything the helpers bring in.
      def logger
        Kitchen.logger
      end

      # Kitchen::Logging's levels, silenced -- the helpers log freely and the
      # output is noise in a test run.
      %i{debug info warn error fatal}.each do |level|
        define_method(level) { |*| nil }
      end
    end

    ALL_HELPERS.each { |mod| klass.include(mod) }
    klass.new(default_config.merge(config))
  end

  # Config the helpers read on nearly every path. Individual examples override
  # what they care about, so each example states only what it is testing.
  def default_config
    {
      binary: "docker",
      socket: "unix:///var/run/docker.sock",
    }
  end
end
