# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'abstractivator/version'

Gem::Specification.new do |spec|
  spec.name          = 'abstractivator'
  spec.version       = Abstractivator::VERSION
  spec.authors       = ['Peter Winton']
  spec.email         = ['pwinton@indigobio.com']
  spec.summary       = %q{Utilities}
  spec.description   = %q{Utilities}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'eventmachine'
  spec.add_development_dependency 'mongoid'

  spec.add_runtime_dependency 'activesupport', '~> 4.0'
end
