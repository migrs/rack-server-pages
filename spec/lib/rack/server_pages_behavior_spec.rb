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
  end
end
