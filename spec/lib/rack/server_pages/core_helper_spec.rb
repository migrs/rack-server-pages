# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

describe Rack::ServerPages::CoreHelper do
  let(:directory) { Dir.mktmpdir('rack-server-pages-halt') }
  let(:app) do
    error_template = File.join(directory, 'forbidden.html')
    Rack::ServerPages.new do |config|
      config.view_path = directory
      config.before do
        halt 403, { Rack::CONTENT_TYPE => 'text/html; charset=utf-8' }, partial(error_template)
      end
    end
  end

  around do |example|
    preference = Rack::ServerPages::Template.instance_variable_get(:@use_tilt)
    example.run
  ensure
    Rack::ServerPages::Template.instance_variable_set(:@use_tilt, preference)
  end

  before do
    File.write(File.join(directory, 'index.html.erb'), 'This page must not render.')
    File.write(File.join(directory, 'forbidden.html.erb'), "<h1><%= 'Forbidden' %></h1>")
  end

  after { FileUtils.remove_entry(directory) }

  %w[ERB Tilt].each do |engine|
    context "with #{engine}" do
      before { Rack::ServerPages::Template.use_tilt(engine == 'Tilt') }

      it 'halts with the rendered template, status, and content type' do
        get '/'
        expect(last_response).to have_attributes(status: 403, content_type: 'text/html; charset=utf-8',
                                                 body: '<h1>Forbidden</h1>')
      end
    end

    describe 'response helpers' do
      let(:action) { proc { halt 'Stopped' } }
      let(:app) do
        callback = action
        Rack::ServerPages.new do |config|
          config.view_path = directory
          config.before(&callback)
        end
      end

      it 'halts with a body without changing the status' do
        get '/'
        expect(last_response).to have_attributes(status: 200, body: 'Stopped')
      end

      context 'with a status and body but no headers' do
        let(:action) { proc { halt 403, 'Denied' } }

        it 'uses the supplied status and body' do
          get '/'
          expect(last_response).to have_attributes(status: 403, body: 'Denied')
        end
      end

      context 'with an already populated response' do
        let(:action) do
          proc do
            response.write('Saved')
            halt
          end
        end

        it 'halts without replacing the existing body' do
          get '/'
          expect(last_response).to have_attributes(status: 200, body: 'Saved')
        end
      end

      context 'with a redirect' do
        let(:action) { proc { redirect '/destination', 303 } }

        it 'sets the location and status without rendering the page' do
          get '/'
          expect(last_response.status).to eq 303
          expect(last_response.headers['Location']).to eq '/destination'
        end
      end

      context 'with a raw partial' do
        let(:action) do
          file = File.join(directory, 'message.txt')
          File.write(file, 'Plain partial')
          proc { halt partial(file) }
        end

        it 'reads non-template partials without interpreting their contents' do
          get '/'
          expect(last_response.body).to eq 'Plain partial'
        end
      end

      context 'with a URL pointing at the application root' do
        let(:action) { proc { halt url } }

        it 'retains the application mount and trailing slash' do
          get '/', {}, 'SCRIPT_NAME' => '/mounted'
          expect(last_response.body).to eq '/mounted/'
        end
      end
    end
  end
end
