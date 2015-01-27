# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'locomotive/wubook/plugin/version'

Gem::Specification.new do |s|
  s.name        = "locomotive_wubook_plugin"
  s.version     = Locomotive::WuBook::VERSION
  s.platform    = Gem::Platform::RUBY

  s.authors     = ["Stefan Eilers"]
  s.email       = "se@intelligentmobiles.com"
  s.homepage    = "http://www.intelligentmobiles.com"
  s.description = "Locomotive plugin for accessing WuBook.net channel manager"
  s.summary     = "Integrates some of the WuBooks 'Wired' interface."
  s.licenses    = ['Private']

  s.add_dependency 'locomotive_plugins',    '~> 1.0'

  s.add_development_dependency 'rspec',     '~> 2.12'
  s.add_development_dependency 'mocha',     '~> 0.13'

  s.required_rubygems_version = ">= 1.3.6"

  s.files           = Dir['Gemfile', '{lib}/**/*', 'README.rb']
  s.require_paths   = ["lib"]
end
