# -*- encoding: utf-8 -*-
require 'bundler/setup'
require './lib/rack/server_pages'

# Tilt settings
require 'tilt'
require 'slim'

# .php as ERB template :)
Rack::ServerPages::Template::ERBTemplate.extensions << 'php' # ERBTemplate
Tilt.register Tilt::ERBTemplate, 'php' # TiltTemplate

run Rack::ServerPages
