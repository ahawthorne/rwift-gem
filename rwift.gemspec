# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rwift/version'

Gem::Specification.new do |spec|
  spec.name          = "rwift"
  spec.version       = Rwift::VERSION
  spec.authors       = ["Andrew Hawthorne"]
  spec.email         = ["andrew@domain7.com"]
  spec.summary       = "Do things to Rackspace Cloudfiles"
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  #spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = "rwift"
  spec.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/)} }
  #spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  #spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "fog"
  spec.add_dependency "progressbar"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
