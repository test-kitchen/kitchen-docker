lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kitchen/docker/docker_version"

Gem::Specification.new do |spec|
  spec.name          = "kitchen-docker"
  spec.version       = Kitchen::Docker::DOCKER_VERSION
  spec.authors       = ["Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.description   = %q{A Docker Driver for Test Kitchen}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/test-kitchen/kitchen-docker"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "test-kitchen", ">= 1.0.0", "< 4.0"
end
