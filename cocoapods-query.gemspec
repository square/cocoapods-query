# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_query.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-query'
  spec.version       = CocoaPodsQuery::VERSION
  spec.authors       = ['Trevor Harmon']
  spec.email         = ['trevorh@squareup.com']
  spec.license       = 'MIT'

  spec.summary       = 'CocoaPods plugin to search for pods'
  spec.description   = 'This plugin for CocoaPods helps locate pods in a project. It can show all pods or filter them based on some search term, such as author name, source file, dependency, and more. It is intended for projects with a large number of dependencies.'
  spec.homepage      = 'https://github.com/square/cocoapods-query'

  spec.files         = Dir['*.md', 'lib/**/*', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'

  spec.add_dependency 'cocoapods', '~> 1.0'
end
