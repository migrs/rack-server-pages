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
  end
end
