#!/usr/bin/env gem build
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sneakers/version'

Gem::Specification.new do |gem|
  gem.name          = 'kicks'
  gem.version       = Sneakers::VERSION
  gem.authors       = ['Dotan Nahum', 'Michael Klishin']
  gem.email         = ['michael@clojurewerkz.org']
  gem.description   = ' Fast background processing framework for Ruby and RabbitMQ '
  gem.summary       = ' Fast background processing framework for Ruby and RabbitMQ '
  gem.homepage      = 'https://github.com/ruby-amqp/kicks'
  gem.metadata      = { 'source_code_uri' => 'https://github.com/ruby-amqp/kicks' }
  gem.license       = 'MIT'
  gem.required_ruby_version = Gem::Requirement.new('>= 2.5')

  gem.files         = `git ls-files`.split($/).reject { |f| f == 'Gemfile.lock' }
  gem.executables   = gem.files.grep(/^bin/)
                         .reject { |f| f =~ %r{^bin/ci} }
                         .map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'bunny', '~> 2.19'
  gem.add_dependency 'byebug'
  gem.add_dependency 'concurrent-ruby', '~> 1.0'
  gem.add_dependency 'rake', '>= 12.3', '< 14.0'
  gem.add_dependency 'serverengine', '~> 2.1'
  gem.add_dependency 'thor'

  # for integration environment (see .travis.yml and integration_spec)
  gem.add_development_dependency 'rabbitmq_http_api_client'
  gem.add_development_dependency 'redis'

  gem.add_development_dependency 'activejob', '>= 6.0'
  gem.add_development_dependency 'activesupport', '>= 6.0'
  gem.add_development_dependency 'guard', '~> 2.18'
  gem.add_development_dependency 'guard-minitest', '~> 2.4'
  gem.add_development_dependency 'minitest', '~> 5.15'
  gem.add_development_dependency 'pry-byebug', '~> 3.9'
  gem.add_development_dependency 'rr', '~> 3.0'
  gem.add_development_dependency 'simplecov', '~> 0.21'
  gem.add_development_dependency 'simplecov-rcov-text'
  gem.add_development_dependency 'unparser', '~> 0.2'
end
