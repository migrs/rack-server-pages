require File.dirname(__FILE__) + '/../../spec_helper'
begin
require 'ruby-debug'
require 'tapp'
rescue LoadError
end

describe 'Rack::ServerPages' do
  describe 'Basic requests' do
    before { get path_info }
    subject { last_response }
    let(:content_type) { 'text/html' }

    should_be_ok        '/'
    should_be_not_found '/hoge'

    should_be_not_found '/inf'
    should_be_ok        '/info'
    should_be_not_found '/info/'
    should_be_ok        '/info.php'
    should_be_ok        '/info.php?a=3'
    should_be_not_found '/info.'
    should_be_not_found '/info.p'
    should_be_not_found '/info.php/'

    should_be_not_found '/example'
    should_be_not_found '/examples'
    should_be_ok        '/examples/'
    should_be_ok        '/examples/index'
    should_be_ok        '/examples/index.html'
    should_be_not_found '/examples/index.htm'
    should_be_not_found '/examples/.htaccess'

    context 'content-type: text/css' do
      let(:content_type) { 'text/css' }
      should_be_ok        '/betty'
      should_be_ok        '/betty.css'
      should_be_ok        '/betty.css.sass'
    end
  end

  describe 'Rack::ServerPages private methods' do
    describe '#evalute_path_info' do
      subject { app.new.__send__(:evalute_path_info, path_info) }

      context '/aaa/bbb.erb' do
        let(:path_info) { '/aaa/bbb.erb' }
        it { should eq %w(aaa/ bbb .erb) }
      end

      context '/aaa/bbb/ccc.erb' do
        let(:path_info) { '/aaa/bbb/ccc.erb' }
        it { should eq %w(aaa/bbb/ ccc .erb) }
      end

      context '/aaa/bbb/ccc.' do
        let(:path_info) { '/aaa/bbb/ccc.' }
        it { should be_nil }
      end

      context '/aaa/bbb/ccc' do
        let(:path_info) { '/aaa/bbb/ccc' }
        it { should eq ['aaa/bbb/', 'ccc', nil] }
      end

      context '/aaa-bbb/ccc' do
        let(:path_info) { '/aaa-bbb/ccc' }
        it { should eq ['aaa-bbb/', 'ccc', nil] }
      end

      context '/aaa/bbb/' do
        let(:path_info) { '/aaa/bbb/' }
        it { should eq ['aaa/bbb/', nil, nil] }
      end

      context '/' do
        let(:path_info) { '/' }
        it { should eq [nil, nil, nil] }
      end
    end
  end

  describe 'Configuration' do
    it 'test' do
      mock_app do
        run Rack::ServerPages
      end
    end
  end
end
