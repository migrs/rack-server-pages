# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

describe Rack::ServerPages do
  let(:directory) { Dir.mktmpdir('rack-server-pages-assets') }
  let(:stylesheet) { File.join(directory, 'styles.css') }
  let(:contents) { 'body { color: rgb(255, 0, 0); }' }
  let(:app) { build_app }

  def build_app(options = {})
    described_class.new do |config|
      config.view_path = directory
      config.cache_control = 'private, no-cache'
      config.static_cache_control = 'public, no-cache'
      options.each { |key, value| config.public_send("#{key}=", value) }
    end
  end

  def fingerprint
    Digest::SHA256.hexdigest(contents)
  end

  before do
    File.write(stylesheet, contents)
    File.write(File.join(directory, 'index.html.erb'),
               '<link rel="stylesheet" href="<%= h asset_path("/styles.css") %>"><h1>Assets</h1>')
    File.write(File.join(directory, 'icon.svg'), '<svg/>')
    File.utime(Time.utc(1980), Time.utc(1980), stylesheet)
  end

  after { FileUtils.remove_entry(directory) }

  def replace_stylesheet
    modified_at = File.mtime(stylesheet)
    File.write(stylesheet, 'body { color: rgb(0, 0, 255); }')
    File.utime(modified_at, modified_at, stylesheet)
  end

  describe '#asset_path' do
    it 'renders a content-versioned stylesheet link in a revalidating page' do
      get '/'
      expect(last_response.body).to include("/styles.css?v=#{fingerprint}")
      expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
    end

    it 'changes the version when contents change but size and mtime do not' do
      original_path = app.asset_path('/styles.css')
      replace_stylesheet
      expect(app.asset_path('/styles.css')).not_to eq original_path
    end

    it 'preserves query values and fragments while replacing the old version' do
      expect(app.asset_path('styles.css?theme=dark&v=old#section'))
        .to eq "/styles.css?theme=dark&v=#{fingerprint}#section"
    end

    it 'raises for a missing asset rather than rendering an unversioned URL' do
      expect { app.asset_path('/missing.css') }.to raise_error Errno::ENOENT
    end

    ['', 'https://example.org/styles.css', '//example.org/styles.css', '/%2e%2e/styles.css'].each do |path|
      it "rejects invalid local asset path #{path.inspect}" do
        expect { app.asset_path(path) }.to raise_error ArgumentError
      end
    end

    context 'with an application mount and effective path' do
      let(:app) { build_app(effective_path: '/pages') }

      it 'includes both prefixes in rendered URLs' do
        get '/pages/', {}, 'SCRIPT_NAME' => '/bot'
        expect(last_response.body).to include("/bot/pages/styles.css?v=#{fingerprint}")
      end
    end

    context 'with multiple view paths' do
      let(:preferred_directory) { File.join(directory, 'preferred') }
      let(:app) { build_app(view_path: [preferred_directory, directory]) }

      before do
        FileUtils.mkdir_p(preferred_directory)
        File.write(File.join(preferred_directory, 'styles.css'), 'preferred')
      end

      it 'fingerprints the same file that request resolution selects' do
        get '/styles.css'
        expect(last_response.body).to eq 'preferred'
        expect(app.asset_path('/styles.css')).to eq "/styles.css?v=#{Digest::SHA256.hexdigest('preferred')}"
      end
    end

    context 'with generated CSS' do
      before do
        FileUtils.rm(stylesheet)
        File.write("#{stylesheet}.erb", 'body { background: url("<%= asset_path("/icon.svg") %>"); }')
      end

      it 'renders versioned references inside CSS templates' do
        get app.asset_path('/styles.css')
        expect(last_response.body).to include("/icon.svg?v=#{Digest::SHA256.hexdigest('<svg/>')}")
        expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
      end

      it 'refreshes image references even when the stylesheet source is unchanged' do
        get app.asset_path('/styles.css')
        original_css = last_response.body
        File.write(File.join(directory, 'icon.svg'), '<svg>new</svg>')
        get app.asset_path('/styles.css')
        expect(last_response.body).not_to eq original_css
      end
    end
  end

  describe 'static revalidation' do
    it 'returns a content ETag and the configured static cache policy' do
      get '/styles.css'
      expect(last_response.headers['ETag']).to eq %("#{fingerprint}")
      expect(last_response.headers['Cache-Control']).to eq 'public, no-cache'
    end

    [->(etag) { etag }, ->(etag) { "W/#{etag}" }, ->(etag) { %("other", #{etag}) }, ->(_etag) { '*' }].each_with_index do |condition, index|
      it "returns an empty 304 for matching conditional request #{index + 1}" do
        get '/styles.css', {}, 'HTTP_IF_NONE_MATCH' => condition.call(%("#{fingerprint}"))
        expect(last_response.status).to eq 304
        expect(last_response.body).to be_empty
      end
    end

    it 'preserves timestamp-only conditional responses' do
      get '/styles.css', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
      expect(last_response.status).to eq 304
      expect(last_response.body).to be_empty
    end

    it 'preserves timestamp-only conditional HEAD responses' do
      head '/styles.css', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
      expect(last_response.status).to eq 304
      expect(last_response.body).to be_empty
    end

    it 'honors a matching ETag even when the timestamp validator does not match' do
      get '/styles.css', {}, 'HTTP_IF_NONE_MATCH' => %("#{fingerprint}"),
                             'HTTP_IF_MODIFIED_SINCE' => Time.utc(1970).httpdate
      expect(last_response.status).to eq 304
      expect(last_response.body).to be_empty
    end

    it 'serves changed contents despite the old ETag and unchanged timestamp' do
      replace_stylesheet
      get '/styles.css', {}, 'HTTP_IF_NONE_MATCH' => %("#{fingerprint}"),
                             'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'body { color: rgb(0, 0, 255); }'
    end

    it 'keeps HEAD responses empty with the same content validator' do
      head '/styles.css'
      expect(last_response.body).to be_empty
      expect(last_response.headers['ETag']).to eq %("#{fingerprint}")
    end

    it 'preserves byte-range responses' do
      get '/styles.css', {}, 'HTTP_RANGE' => 'bytes=0-3'
      expect(last_response.status).to eq 206
      expect(last_response.body).to eq 'body'
    end

    it 'does not turn an unsupported method into a cached success' do
      post '/styles.css', {}, 'HTTP_IF_NONE_MATCH' => '*'
      expect(last_response.status).to eq 405
    end

    it 'preserves not-found responses for directories with file-like names' do
      FileUtils.mkdir_p(File.join(directory, 'not-a-file.css'))
      get '/not-a-file.css'
      expect(last_response.status).to eq 404
    end

    context 'without a static cache policy' do
      let(:app) { build_app(static_cache_control: nil) }

      it 'leaves cache policy unset by default' do
        get '/styles.css'
        expect(last_response.headers['Cache-Control']).to be_nil
      end
    end

    context 'with static timestamp validation disabled' do
      let(:app) { build_app(static_timestamps: false) }

      it 'returns the file for a matching timestamp while retaining Last-Modified' do
        get '/styles.css', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
        expect(last_response.status).to eq 200
        expect(last_response.headers['Last-Modified']).to eq File.mtime(stylesheet).httpdate
      end

      it 'ignores matching timestamps on HEAD requests' do
        head '/styles.css', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
        expect(last_response.status).to eq 200
        expect(last_response.body).to be_empty
      end

      it 'still honors matching ETags' do
        get '/styles.css', {}, 'HTTP_IF_NONE_MATCH' => %("#{fingerprint}"),
                               'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
        expect(last_response.status).to eq 304
        expect(last_response.body).to be_empty
      end

      context 'with static ETags also disabled' do
        let(:app) { build_app(static_timestamps: false, static_etags: false) }

        it 'ignores both validators and serves the file' do
          get '/styles.css', {}, 'HTTP_IF_NONE_MATCH' => %("#{fingerprint}"),
                                 'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq contents
        end
      end
    end

    context 'with static ETags disabled' do
      let(:app) { build_app(static_etags: false) }

      it 'serves static files without content hashing or ETags' do
        allow(Digest::SHA256).to receive(:file).and_call_original
        get '/styles.css'
        expect(Digest::SHA256).not_to have_received(:file)
        expect(last_response.headers['ETag']).to be_nil
      end

      it 'retains the configured static cache policy' do
        get '/styles.css'
        expect(last_response.status).to eq 200
        expect(last_response.headers['Cache-Control']).to eq 'public, no-cache'
      end

      it 'preserves Rack timestamp-based conditional responses' do
        get '/styles.css', {}, 'HTTP_IF_MODIFIED_SINCE' => File.mtime(stylesheet).httpdate
        expect(last_response.status).to eq 304
        expect(last_response.body).to be_empty
      end

      it 'still supports content-versioned asset URLs' do
        expect(app.asset_path('/styles.css')).to eq "/styles.css?v=#{fingerprint}"
      end
    end
  end

  context 'with a browser that has already loaded the page' do
    let(:browser) { Capybara::Session.new(:selenium, app) }

    before { browser.visit('/') }

    after { browser.driver.quit }

    it 'loads the new stylesheet after reload without clearing browser storage' do
      expect(browser.evaluate_script('getComputedStyle(document.body).color')).to eq 'rgb(255, 0, 0)'
      replace_stylesheet
      browser.refresh
      expect(browser.evaluate_script('getComputedStyle(document.body).color')).to eq 'rgb(0, 0, 255)'
    end
  end
end
