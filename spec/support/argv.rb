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

require "shellwords"

# Helpers for asserting on generated command lines.
#
# The driver builds `docker` invocations as single strings and hands them to a
# shell. Asserting on those strings with `include` is misleading: the string
# "-v /my volume:/data" contains "-v /my volume:/data", but the shell will tear
# it into three arguments and Docker will reject it. Splitting the command the
# way a shell would, and asserting on the resulting argument vector, is the only
# way for a test to see what Docker will actually receive.
module ArgvHelpers
  # Splits a generated command line the way a shell would.
  #
  # @param command [String] the command line the driver built
  # @return [Array<String>] the arguments Docker will actually receive
  def argv(command)
    Shellwords.split(command)
  end
end

# Asserts that a flag and its value survive shell splitting as one argument
# each, and remain adjacent.
#
# `include` alone cannot express this: an argv of ["-v", "/my", "volume:/data"]
# includes "-v", and includes "/my", and would satisfy a naive assertion while
# being completely broken.
RSpec::Matchers.define :include_consecutive do |*expected|
  match do |actual|
    actual.each_cons(expected.length).any? { |window| window == expected }
  end

  failure_message do |actual|
    "expected the argument vector to contain #{expected.inspect} as consecutive arguments\n" \
      "                                 got: #{actual.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected the argument vector not to contain #{expected.inspect} as consecutive arguments\n" \
      "                                     got: #{actual.inspect}"
  end
end
