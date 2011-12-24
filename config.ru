require 'bundler/setup'
require 'rack'
require 'rack/contrib/try_static'
require 'tilt'
require 'tapp'
require File.dirname(__FILE__) + '/lib/rack/server_pages'


use Rack::ServerPages,
    :root => "public",
    :urls => %w[/]

require 'slim'
require 'rdiscount'
Tilt.prefer Tilt::RDiscountTemplate

def time_now
  Time.now.to_s
end

run lambda {|e| [404, {'Content-Type' => 'text/html'}, ['File Not Found']]}
