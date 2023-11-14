lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/docker/docker_version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen-docker'
  spec.version       = Kitchen::Docker::DOCKER_VERSION
  spec.authors       = ['Sean Porter']
  spec.email         = ['portertech@gmail.com']
  spec.description   = %q{A Docker Driver for Test Kitchen}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/test-kitchen/kitchen-docker'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'test-kitchen', '>= 1.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  # Style checker gems.
  spec.add_development_dependency 'cane'
  spec.add_development_dependency 'tailor'
  spec.add_development_dependency 'countloc'

  # Unit testing gems.
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'fuubar', '~> 2.0'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency 'codecov', '~> 0.0', '>= 0.0.2'
  spec.add_development_dependency 'chefstyle'

  # Integration testing gems.
  spec.add_development_dependency 'kitchen-inspec', '~> 2.0'
  spec.add_development_dependency 'train', '>= 2.1', '< 4.0' # validate 4.x when it's released
end
