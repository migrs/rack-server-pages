# -*- coding: utf-8 -*-
require 'ruby-debug'
require 'time'
require 'rack/utils'
require 'rack/mime'
=begin
  features:
  - render with tilt

  todo:
  - mime-type
  - sample.php :)

  sinatra extension:
  - layout template
  - include template
  - scope
=end

module Rack
  class ServerPages

    def initialize(app, options = {})
      @app = app
      @root = options[:root] || 'public'
      @cache_control = options[:cache_control]
    end

    def call(env)
      req = {}.tap do |h|
        m = env['PATH_INFO'].match(%r{^/((?:[\w-]+/)+)?(\w+)?(\.\w+)?$})
        h.merge! :dir => m[1], :file => m[2], :ext => m[3]
        h[:file] ||= 'index'
      end

      template_files = Dir["#{@root}/#{req[:dir]}#{req[:file]}.*"]

      if template_files.size > 0
        template_file = template_files[0]
        response_type, template_ext = template_file.match(/(\.\w+)?(\.\w+)$/).captures
        response_type = req[:ext] if response_type.nil?

        if template = Tilt[template_ext]
          [200, {
            'Last-Modified'  => ::File.mtime(template_file).httpdate,
            'Content-Type'   => response_type ? Mime.mime_type(response_type) : template.default_mime_type,
          }, []].tap do |_, h, output|
            output << template.new(template_file).render
            h['Content-Length'] = Rack::Utils.bytesize(output[0]).to_s
            h['Cache-Control']  = @cache_control if @cache_control
          end
        else
          Rack::File.new(@root).call(env)
        end
      else
        @app.call(env)
      end
    end
  end
end

