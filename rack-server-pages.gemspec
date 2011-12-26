# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack-server-pages"

Gem::Specification.new do |s|
  s.name        = "rack-server-pages"
  s.version     = Rack::ServerPages::VERSION
  s.authors     = ["Masato Igarashi"]
  s.email       = ["m@igrs.jp"]
  s.homepage    = "http://m.igrs.jp/"
  s.summary     = %q{Rack middleware that serve a view templates directly with tilt.}
  s.description = %q{There are no controllers and no models, just only views like a asp, jsp and php!}

  s.rubyforge_project = "rack-server-pages"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rack'
  s.add_dependency 'tilt'
  s.add_development_dependency 'slim'
end
