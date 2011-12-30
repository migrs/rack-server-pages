# -*- encoding: utf-8 -*-
require 'bundler/setup'
require './lib/rack/server_pages'

# Tilt settings
require 'tilt'
require 'slim'

# .php as ERB template :)
Tilt.register Tilt::ERBTemplate, 'php'
Rack::ServerPages::Template::ERBTemplate.extensions << 'php'

run Rack::ServerPages
