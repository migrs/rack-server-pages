#ENV['RACK_ENV'] = 'test'
require 'rack/test'
#SimpleCov.start if defined? SimpleCov

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Rack::Builder.app do
    use Rack::ServerPages,
      :root => File.dirname(__FILE__) + '/../public'
    lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'OK'] }
  end
end
