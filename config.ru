require 'bundler/setup'
require 'tapp'
require File.dirname(__FILE__) + '/lib/rack/server_pages'

require 'slim'
require 'rdiscount'

use Rack::ServerPages

Tilt.prefer Tilt::RDiscountTemplate
Tilt.register Tilt::ErubisTemplate, 'php'
Tilt::ErubisTemplate.default_mime_type = 'text/html'

run lambda {|e| [404, {'Content-Type' => 'text/plain'}, ['Not Found']]}
