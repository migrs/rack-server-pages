# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

describe Rack::ServerPages do
  let(:directory) { Dir.mktmpdir('rack-server-pages-behavior') }
  let(:events) { [] }
  let(:show_exceptions) { false }
  let(:template) { '<% events << :render %>Rendered' }
  let(:app) do
    recorded_events = events
    fallback = ->(_env) { [418, { Rack::CONTENT_TYPE => 'text/plain' }, ['Downstream']] }
    described_class.new(fallback) do |config|
      config.view_path = directory
      config.show_exceptions = show_exceptions
      config.helpers { define_method(:events) { recorded_events } }
      config.before { recorded_events << :before }
      config.after { recorded_events << :after }
      config.on_error do
        recorded_events << :on_error
        response.body = ['Render failed']
        response['Content-Type'] = 'text/plain'
      end
    end
  end

  before { File.write(File.join(directory, 'index.html.erb'), template) }

  after { FileUtils.remove_entry(directory) }

  it 'runs filters and helpers around a successful template render' do
    get '/'
    expect(last_response.body).to eq 'Rendered'
    expect(events).to eq [:before, :render, :after]
  end

  it 'leaves unmatched requests and their response to the downstream app' do
    get '/missing'
    expect(last_response).to have_attributes(status: 418, body: 'Downstream')
    expect(events).to be_empty
  end

  context 'with the application shorthand and a fallback page' do
    let(:app) do
      fallback = described_class::NotFound[File.join(directory, 'missing.html')]
      described_class[] do |config|
        config.view_path = directory
        config.failure_app = fallback
      end
    end

    before { File.write(File.join(directory, 'missing.html'), 'Custom not found') }

    it 'serves the configured not-found page for an unmatched request' do
      get '/missing-page'
      expect(last_response).to have_attributes(status: 404, body: 'Custom not found')
    end

    context 'when the fallback file is absent' do
      before { FileUtils.rm(File.join(directory, 'missing.html')) }

      it 'uses the built-in not-found response' do
        get '/missing-page'
        expect(last_response).to have_attributes(status: 404, body: 'Not Found: /missing-page')
      end
    end
  end

  context 'with method-based filters' do
    let(:app) do
      recorded_events = events
      helper = Module.new do
        define_method(:events) { recorded_events }
        define_method(:prepare) { recorded_events << :prepare }
      end
      described_class.new do |config|
        config.view_path = directory
        config.helpers helper
        config.before helper.instance_method(:prepare)
      end
    end

    it 'binds method filters to the rendering scope before rendering' do
      get '/'
      expect(last_response.body).to eq 'Rendered'
      expect(events).to eq [:prepare, :render]
    end
  end

  context 'when rendering raises' do
    let(:template) { '<% raise "broken template" %>' }

    it 'returns a custom error response and still runs after filters' do
      get '/'
      expect(last_response).to have_attributes(status: 500, body: 'Render failed')
      expect(events).to eq [:before, :on_error, :after]
    end

    context 'when exceptions are exposed' do
      let(:show_exceptions) { true }

      it 'propagates the original error while still running after filters' do
        expect { get '/' }.to raise_error RuntimeError, 'broken template'
        expect(events).to eq [:before, :after]
      end
    end

    [nil, 'development', 'production'].each do |environment|
      context "with the default exception policy in #{environment.inspect}" do
        let(:show_exceptions) { nil }

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('RACK_ENV').and_return(environment)
        end

        if environment == 'production'
          it 'handles the rendering error as a server error' do
            get '/'
            expect(last_response).to have_attributes(status: 500, body: 'Render failed')
          end
        else
          it 'exposes the rendering error' do
            expect { get '/' }.to raise_error RuntimeError, 'broken template'
          end
        end
      end
    end
  end
end
