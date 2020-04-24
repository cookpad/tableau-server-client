# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tableau_server_client/version'

Gem::Specification.new do |spec|
  spec.name          = "tableau_server_client"
  spec.version       = TableauServerClient::VERSION
  spec.authors       = ["shimpeko"]
  spec.email         = ["shimpeko@swimmingpython.com"]

  spec.summary       = %q{Tableau Server REST API Client}
  spec.description   = %q{REST API Client for Tableau Server.}
  spec.homepage      = "https://github.com/shimpeko/tableau-server-client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = ["console"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug"

  spec.add_dependency 'faraday', '>= 0.15.3'
  spec.add_dependency 'nokogiri', '>= 1.8.2'
  spec.add_dependency 'pry', '>= 0.11.3'
  spec.add_dependency 'rubyzip', '>= 1.2.1'
end
