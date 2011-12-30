# -*- encoding: utf-8 -*-
require 'bundler/setup'
require './lib/rack/server_pages'

Rack::ServerPages::Template::ERBTemplate::EXTENSIONS << 'php'
# Tilt settings
require 'tilt'
Tilt.prefer Tilt::RDiscountTemplate
Tilt.register Tilt::ERBTemplate, 'php'
Tilt::ERBTemplate.default_mime_type = 'text/html'

use Rack::ServerPages do |config|
  config.view_path = 'views/examples'
end

run Rack::ServerPages::NotFound
