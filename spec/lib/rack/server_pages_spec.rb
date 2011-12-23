require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../../lib/rack/server_pages'

describe 'Rack::ServerPages' do
  describe 'index' do
    pending do
    before { get '/' }
    subject { last_response }
    it { should be_ok }
    end
  end
end
