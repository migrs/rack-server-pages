require 'bundler/setup'
require 'rack'
require 'rack/contrib/try_static'
require 'tilt'
require 'tapp'
require File.dirname(__FILE__) + '/lib/rack/server_pages'

use Rack::ServerPages,
    :root => "public",
    :urls => %w[/]

require 'rdiscount'
Tilt.prefer Tilt::RDiscountTemplate

run lambda {|e| [404, {'Content-Type' => 'text/html'}, ['File Not Found']]}
