# -*- encoding: utf-8 -*-
require 'bundler/setup'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'rack-server-pages'

# Tilt settings
require 'tilt'
require 'slim'

# .php as ERB template :)
Rack::ServerPages::Template::ERBTemplate.extensions << 'php' # ERBTemplate
# Rack::ServerPages::Template.use_tilt false
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
  # config.show_exceptions = false

  config.on_error do
    response.body = ['Error!']
  end

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
