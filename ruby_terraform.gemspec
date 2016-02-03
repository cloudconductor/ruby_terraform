# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_terraform/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_terraform'
  spec.version       = RubyTerraform::VERSION
  spec.authors       = ['Yo Takezawa']
  spec.email         = ['takezawa.yo@tis.co.jp']

  spec.summary       = 'Execute terraform from ruby'
  spec.description   = 'This gem can execute terraform plan, apply or destroy that are provided by hashicorp'
  spec.homepage      = 'https://github.com/cloudconductor/ruby_terraform'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'systemu', '~> 2.6'
end
