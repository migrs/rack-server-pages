# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'rack-server-pages/version'

Gem::Specification.new do |s|
  s.name        = 'rack-server-pages'
  s.version     = Rack::ServerPages::VERSION
  s.authors     = ['Masato Igarashi', 'Daniel Doubrovkine']
  s.email       = ['m@igrs.jp']
  s.homepage    = 'http://github.com/migrs/rack-server-pages'
  s.licenses    = ['MIT']
  s.summary     = 'Rack middleware and appilcation for serving dynamic pages.'
  s.description = 'Rack middleware and appilcation for serving dynamic pages in very simple way, without controllers or models, only views similar to ASP, JSP and PHP.'

  s.files = Dir['lib/**/*', 'CHANGES.md', 'README.md', 'LICENSE.md', 'rack-server-pages.gemspec']

  s.require_paths = ['lib']

  s.add_dependency 'rack'
end
