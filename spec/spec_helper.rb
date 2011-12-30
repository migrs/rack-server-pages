# -*- encoding: utf-8 -*-
require 'rack/test'
require 'ruby-debug'
require 'tapp'
require 'simplecov'
require File.dirname(__FILE__) + '/../lib/rack/server_pages'
SimpleCov.start

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

require 'tilt'
require 'slim'
Tilt.register Tilt::ERBTemplate, 'php'

def app
  @app ||=Rack::Builder.app do
    run Rack::ServerPages
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
    its(:content_type) { should match %r{\btext/html\b} }
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
