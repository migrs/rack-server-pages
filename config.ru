require 'bundler/setup'
require 'tapp'
require File.dirname(__FILE__) + '/lib/rack/server_pages'

require 'slim'
require 'rdiscount'

Tilt.prefer Tilt::RDiscountTemplate

Tilt.register Tilt::ErubisTemplate, 'php'
Tilt::ErubisTemplate.default_mime_type = 'text/html'

use Rack::ServerPages

run lambda {|e| [404, {'Content-Type' => 'text/plain'}, ['Not Found']]}
