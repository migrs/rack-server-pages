require File.dirname(__FILE__) + '/../../spec_helper'

describe 'Rack::ServerPages' do
  describe 'Basic requests' do
    should_be_ok '/'
    should_be_ok '/info'
    should_be_ok '/info.php'
    should_be_ok '/examples/'
    should_be_ok '/examples/index'
    should_be_ok '/examples/index.html'

    should_be_not_found '/hoge'
    should_be_not_found '/inf'
    should_be_not_found '/info.'
    should_be_not_found '/info.p'
    should_be_not_found '/info.php/'
    should_be_not_found '/example'
    should_be_not_found '/examples'

    #should_be_not_found '/examples/index.htm'
    #should_be_not_found '/examples/.htaccess'
  end
end
