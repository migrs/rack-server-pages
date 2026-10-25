# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Rack::ServerPages::Template do
  let(:loaded_tilt) { Tilt }
  let(:scope) { Rack::ServerPages::Binding.new(Rack::MockRequest.env_for('/')) }

  around do |example|
    preference = described_class.instance_variable_get(:@use_tilt)
    described_class.instance_variable_set(:@use_tilt, nil)
    example.run
  ensure
    described_class.instance_variable_set(:@use_tilt, preference)
  end

  before { loaded_tilt }

  it 'uses the template lookup API when Tilt is loaded' do
    expect(described_class.engine).to eq described_class::TiltTemplate
  end

  it 'respects an explicit opt-out even when Tilt is loaded' do
    described_class.use_tilt(false)
    expect(described_class.engine).to eq described_class::ERBTemplate
  end

  context 'without a Tilt constant' do
    before { hide_const('Tilt') }

    it 'uses the built-in ERB engine' do
      expect(described_class.engine).to eq described_class::ERBTemplate
    end

    it 'detects Tilt loaded after an earlier ERB request' do
      expect(described_class.engine).to eq described_class::ERBTemplate
      stub_const('Tilt', loaded_tilt)
      expect(described_class.engine).to eq described_class::TiltTemplate
    end
  end

  context 'with an incomplete Tilt namespace from another dependency' do
    before { stub_const('Tilt', Module.new) }

    it 'does not mistake the namespace for the loaded template library' do
      expect(described_class.engine).to eq described_class::ERBTemplate
    end

    it 'renders ERB without requiring the optional Tilt dependency' do
      Tempfile.create(['rack-server-pages-tilt', '.erb']) do |file|
        file.write('<%= "Rendered with ERB" %>')
        file.flush
        expect(described_class[file.path].render(scope)).to eq 'Rendered with ERB'
      end
    end

    it 'detects the full library after the namespace is initialized' do
      expect(described_class.engine).to eq described_class::ERBTemplate
      stub_const('Tilt', loaded_tilt)
      expect(described_class.engine).to eq described_class::TiltTemplate
    end
  end
end
