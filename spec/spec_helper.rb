require 'rack/test'
require 'ruby-debug'
require 'tapp'
require 'simplecov'
SimpleCov.start
require File.dirname(__FILE__) + '/../lib/rack/server_pages'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

require 'slim'
Tilt.register Tilt::ErubisTemplate, 'php'
Tilt::ErubisTemplate.default_mime_type = 'text/html'

def app
  @app ||=Rack::Builder.app do
    use Rack::ServerPages
    run lambda {|e| [404, {'Content-Type' => 'text/plain'}, ['Not Found']]}
  end
end

def mock_app(&block)
  @app = Rack::Builder.app(&block)
end

def should_be_ok(path)
  describe "GET #{path}" do
    before { get path }
    subject { last_response }
    it { should be_ok }
    its(:content_type) { should eq 'text/html' }
  end
end

def should_be_not_found(path)
  describe "GET #{path}" do
    before { get path }
    subject { last_response }
    it { should be_not_found }
    #its(:content_type) { should eq 'text/plain' }
  end
end
