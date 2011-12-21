module Rack
  class Static

    def initialize(app, options={})
      @app = app
      @urls = options[:urls] || ["/favicon.ico"]
      root = options[:root] || Dir.pwd
      cache_control = options[:cache_control]
      @file_server = Rack::File.new(root, cache_control)
    end

    def call(env)
      path = env["PATH_INFO"]

      unless @urls.kind_of? Hash
        can_serve = @urls.any? { |url| path.index(url) == 0 }
      else
        can_serve = @urls.key? path
      end

      if can_serve
        env["PATH_INFO"] = @urls[path] if @urls.kind_of? Hash
        @file_server.call(env)
      else
        @app.call(env)
      end
    end

  end
end
