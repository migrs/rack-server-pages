# -*- encoding: utf-8 -*-
require 'bundler/setup'
require 'rack-server-pages'
#require 'slim'

Rack::ServerPages::Template::ERBTemplate::EXTENSIONS << 'php'
use Rack::ServerPages
run lambda {|e| [404, {'Content-Type' => 'text/plain'}, ["Not Found: #{e['REQUEST_PATH']}"]]}

#Tilt.prefer Tilt::RDiscountTemplate
#Tilt.register Tilt::ERBTemplate, 'php'
#Tilt::ERBTemplate.default_mime_type = 'text/html'
