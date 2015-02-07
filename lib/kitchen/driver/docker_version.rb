# -*- encoding: utf-8 -*-
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

require File.join(File.dirname(__FILE__), \
                  '..', \
                  '..', \
                  'kitchen_docker', \
                  'version')
module Kitchen

  module Driver
    # Version string for Docker Kitchen driver
    # Maintained by gem-release, refer to kitchen_docker/version.rb
    # Kept this module/class as it is the way test-kitchen does it
    DOCKER_VERSION = KitchenDocker::VERSION
  end
end
