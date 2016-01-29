# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activefacts/metamodel/version'

Gem::Specification.new do |spec|
  spec.name          = "activefacts-metamodel"
  spec.version       = ActiveFacts::Metamodel::VERSION
  spec.authors       = ["Clifford Heath"]
  spec.email         = ["clifford.heath@gmail.com"]

  spec.summary       = %q{Core meta-model for fact-based models (schema)}
  spec.description   = %q{
Core meta-model for fact-based models (schema).
This gem provides the core representations for the Fact Modeling tools of ActiveFacts.
  }
  spec.homepage      = "https://github.com/cjheath/activefacts-metamodel"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.10", "~> 1.10.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"

  spec.add_runtime_dependency "activefacts-api", "~> 1", ">= 1.9.4"
  spec.add_development_dependency "activefacts", "~> 1", "~> 1.8"
end
