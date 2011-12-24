# -*- coding: utf-8 -*-
require 'ruby-debug'
require 'time'
require 'rack/utils'
require 'rack/mime'
=begin
  features:
  - render with tilt
  - mime-type
  - sample.php :)
  - path_regex

  todo:
  - rack request
  - session
  - params

  sinatra extension:
  - layout template
  - include template
  - scope
=end

module Rack
  class ServerPages

    def initialize(app, options = {})
      @app = app
      @path = options[:path] || '/'
      @roots = options[:root].kind_of?(Enumerable) ? options[:root] :
        (options[:root].nil? or options[:root].empty?) ? %w(views public) : [options[:root].to_s]
      @cache_control = options[:cache_control]
    end

    def call(env)
      req = {}.tap do |h|
        if m = env['PATH_INFO'].match(%r!^#{@path}((?:[\w-]+/)+)?(\w+)?(\.\w+)?$!)
          h.merge! :dir => m[1], :file => m[2], :ext => m[3]
          h[:file] ||= 'index'
        end
      end

      template_files = Dir[@roots.map{|root|"#{root}/#{req[:dir]}#{req[:file]}.*"}.join("\0")] unless req.empty?

      if template_files and template_files.size > 0
        template_file = template_files[0]
        response_type, template_ext = template_file.match(/(\.\w+)?(\.\w+)$/).captures
        response_type = req[:ext] if response_type.nil?

        if template = Tilt[template_ext]
          scope = Binding.new(env)
          scope.response.tap do |res|
            res.write template.new(template_file).render(scope)
            res['Last-Modified'] ||= ::File.mtime(template_file).httpdate
            res['Content-Type']  ||= response_type ? Mime.mime_type(response_type, template.default_mime_type) : template.default_mime_type
            res['Cache-Control'] ||= @cache_control if @cache_control
          end.finish
        else
          StaticFile.new(template_file, @cache_control).call(env)
        end
      else
        @app.call(env)
      end
    end

    class StaticFile < File
      def initialize(path, cache_control = nil)
        @path = path
        @cache_control = cache_control
      end

      def _call(env)
        serving(env)
      end
    end

    class Binding
      extend Forwardable

      attr_reader :request
      attr_reader :response

      def_delegators :request, :env, :params, :session, :logger, :headers

      def initialize(env)
        @request  = Rack::Request.new(env)
        @response = Rack::Response.new
      end
    end
  end
end

