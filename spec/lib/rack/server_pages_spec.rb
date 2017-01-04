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

    context 'content-type: image/png' do
      let(:content_type) { 'image/png' }
      should_be_ok        '/rack_logo.png'
      should_be_ok        '/rack_logo@2x.png'
    end
  end

  describe 'Rack::ServerPages private methods' do
    describe '#evalute_path_info' do
      subject { m = app.new.instance_variable_get(:@path_regex).match(path_info); m[1, 3] if m }

      context '/aaa/bbb.erb' do
        let(:path_info) { '/aaa/bbb.erb' }
        it { is_expected.to eq %w(aaa/ bbb .erb) }
      end

      context '/aaa/bbb/ccc.erb' do
        let(:path_info) { '/aaa/bbb/ccc.erb' }
        it { is_expected.to eq %w(aaa/bbb/ ccc .erb) }
      end

      context '/aaa/bbb/ccc.' do
        let(:path_info) { '/aaa/bbb/ccc.' }
        it { is_expected.to be_nil }
      end

      context '/aaa/bbb/ccc' do
        let(:path_info) { '/aaa/bbb/ccc' }
        it { is_expected.to eq ['aaa/bbb/', 'ccc', nil] }
      end

      context '/aaa-bbb/ccc' do
        let(:path_info) { '/aaa-bbb/ccc' }
        it { is_expected.to eq ['aaa-bbb/', 'ccc', nil] }
      end

      context '/aaa/bbb/' do
        let(:path_info) { '/aaa/bbb/' }
        it { is_expected.to eq ['aaa/bbb/', nil, nil] }
      end

      context '/' do
        let(:path_info) { '/' }
        it { is_expected.to eq [nil, nil, nil] }
      end

      context path = '/aaa/bbb/AB-c.182-d.min.js' do
        let(:path_info) { path }
        it { is_expected.to eq ['aaa/bbb/', 'AB-c.182-d.min', '.js'] }
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
