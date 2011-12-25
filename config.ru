require 'slim'

use Rack::ServerPages

Tilt.prefer Tilt::RDiscountTemplate
Tilt.register Tilt::ERBTemplate, 'php'
Tilt::ERBTemplate.default_mime_type = 'text/html'

run lambda {|e| [404, {'Content-Type' => 'text/plain'}, ['Not Found']]}
