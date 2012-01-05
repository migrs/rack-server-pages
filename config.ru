# -*- encoding: utf-8 -*-
require 'bundler/setup'
require './lib/rack/server_pages'

# Tilt settings
require 'tilt'
require 'slim'

# .php as ERB template :)
Rack::ServerPages::Template::ERBTemplate.extensions << 'php' # ERBTemplate
Tilt.register Tilt::ERBTemplate, 'php' # TiltTemplate

module SampleHelper
  def before
    @sample1 = 'sample1'
  end

  def sample5
    'sample5'
  end

  def after
  end
end

run Rack::ServerPages.new { |config|
  config.helpers SampleHelper
  config.helpers do
    def sample4
      'sample4'
    end
  end

  config.before do
    @sample2 = 'sample2'

    def sample3
      'sample3'
    end
  end
}
