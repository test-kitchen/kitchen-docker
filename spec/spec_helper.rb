#
# Copyright 2016, Noah Kantrowitz
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

require "rake"
require "rspec"
require "rspec/its"

require "kitchen/driver/docker"
require "kitchen/transport/docker"

Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

# These specs never talk to a Docker daemon. Everything this gem does is turn
# configuration into Dockerfiles and `docker` command lines, and turn Docker's
# output back into ids and ports, so all of it can be exercised as pure string
# work. Anything that genuinely needs a daemon belongs in the Test Kitchen
# integration suites -- see CONTRIBUTING.md.
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Fail if an example stubs a method the real object does not have. Without
    # this, a rename in lib/ leaves the specs stubbing a method that no longer
    # exists and passing while the driver is broken.
    mocks.verify_partial_doubles = true
  end

  # Surface deprecations as failures rather than warnings that scroll past.
  config.raise_errors_for_deprecations!

  config.include ArgvHelpers
  config.include HelperHarness
  config.include DockerOutput

  # Basic configuration
  config.run_all_when_everything_filtered = true
  config.filter_run(:focus)

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
  Kernel.srand config.seed
end
