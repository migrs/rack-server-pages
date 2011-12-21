require 'rack'
require 'rack/contrib/try_static'
require File.dirname(__FILE__) + '/lib/rack/server_pages'

use Rack::ServerPages,
    :root => "public",
    :urls => %w[/],
    :try => ['.html', 'index.html', '/index.html']

run lambda {|e| [404, {'Content-Type' => 'text/html'}, ['File Not Found']]}
