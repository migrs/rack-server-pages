# -*- coding: utf-8 -*-
module Rack
  class ServerPages
    def initialize(app, options = {})
      @app = app
      #@try = ['', *options.delete(:try)]
      @root = options[:root] || 'public'
      @static_ext = %w(html)
      @static = ::Rack::Static.new( lambda {|e| [404, {}, []] }, options)
    end

    def call(env)
      orig_path = env['PATH_INFO']
      found = nil
      orig_path =~ /^(.*)\.(\w+)$/
      path = $1
      ext = $2
      if @static_ext.include?(ext)
        @static.call(env.merge!({'PATH_INFO' => orig_path}))
      elsif template = Tilt[ext]
        [200, {"Content-Type" => "text/html"}, [Tilt.new("#{@root}/#{path}.#{ext}").render.tapp]]
      else
        @app.call(env.merge!('PATH_INFO' => orig_path))
      end
    end
  end
end
