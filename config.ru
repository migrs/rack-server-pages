require 'bundler/setup'
require 'rack'
require 'rack/contrib/try_static'
require 'tilt'
require 'tapp'
require File.dirname(__FILE__) + '/lib/rack/server_pages'



require 'slim'
require 'rdiscount'

Tilt.prefer Tilt::RDiscountTemplate

Tilt.register Tilt::ErubisTemplate, 'php'
Tilt::ErubisTemplate.default_mime_type = 'text/html'

use Rack::ServerPages#, :scope => Hoge.new

run lambda {|e| [404, {'Content-Type' => 'text/html'}, ['File Not Found']]}
