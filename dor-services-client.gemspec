# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dor/services/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'dor-services-client'
  spec.version       = Dor::Services::Client::VERSION
  spec.authors       = ['Justin Coyne', 'Michael Giarlo']
  spec.email         = ['jcoyne@justincoyne.com', 'leftwing@alumni.rutgers.edu']

  spec.summary       = 'A client for dor-services-app'
  spec.homepage      = 'https://github.com/sul-dlss/dor-services-client'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 4.2', '< 7'
  spec.add_dependency 'cocina-models', '~> 0.22.1'
  spec.add_dependency 'deprecation', '>= 0'
  spec.add_dependency 'faraday', '~> 0.15'
  spec.add_dependency 'moab-versioning', '~> 4.0'
  spec.add_dependency 'zeitwerk', '~> 2.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.61.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
end
