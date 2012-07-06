# -*- encoding: utf-8 -*-
require File.expand_path('../lib/emmett/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Darcy Laycock"]
  gem.email         = ["darcy@filtersquad.com"]
  gem.description   = %q{Tools to make building API docs simpler.}
  gem.summary       = %q{Tools to make building API docs simpler.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "emmett"
  gem.require_paths = ["lib"]
  gem.version       = Emmett::VERSION

  gem.add_dependency 'github-markdown'
  gem.add_dependency 'github-markup'
  gem.add_dependency 'nokogiri'
  gem.add_dependency 'pygments.rb'
  gem.add_dependency 'handlebars'
  gem.add_dependency 'rake'
  gem.add_dependency 'oj'
  gem.add_dependency 'http_parser.rb'

end
