# -*- encoding: utf-8 -*-
require 'rack'
require 'time'
require 'rack/utils'
require 'rack/mime'
require 'rack/logger'
require 'forwardable'

module Rack
  class ServerPages
    VERSION = '0.0.2'

    def self.call(env)
      new.call(env)
    end

    def self.[](options={}, &block)
      new(nil, options, &block)
    end

    def initialize(app = nil, options = {})
      @config = Config.new(*options)
      yield @config if block_given?
      @app = app || @config.failure_app || NotFound
    end

    def call(env)
      serving(env)
    end

  private

    def serving(env)
      files = find_template_files *evalute_path_info(env['PATH_INFO']) rescue nil

      unless files.nil? or files.empty?
        file = select_template_file(files)

        if template = Template[file, @config]
          template.call(env)
        else
          StaticFile.new(file, @config.cache_control).call(env)
        end
      else
        @app.call(env)
      end
    end

    def evalute_path_info(path)
      if m = path.match(%r!^#{@config.effective_path}/((?:[\w-]+/)+)?([A-z0-9]\w*)?(\.\w+)?(\.\w+)?$!)
        m[1,3] # dir, file, ext
      end
    end

    def find_template_files(dir, file, ext)
      #path = @config.view_paths.map{|root|"#{root}/#{dir}#{file||'index'}#{ext}{.*,}"}.join("\0") # Ruby 1.8
      #path = @config.view_paths.map{|root|"#{root}/#{dir}#{file||'index'}#{ext}{.*,}"} # Ruby 1.9
      #Dir[path].select{|s|s.include?('.')}
      [].tap do |files| # universal way
        @config.view_paths.each do |root|
          files.concat Dir["#{root}/#{dir}#{file||'index'}#{ext}{.*,}"].select{|s|s.include?('.')}
        end
      end
    end

    def select_template_file(files)
      files.first
    end

    class Config < Hash
      def self.hash_accessor(*names)
        names.each do |name|
          define_method("#{name}=") { |v| self[name] = v }
          define_method(name) { self[name] }
        end
      end

      hash_accessor :view_path, :effective_path, :cache_control, :default_charset, :failure_app

      def initialize
        super
        self[:default_charset] ||= 'utf-8'
        self[:view_path] ||= %w(views public)
      end

      def view_paths
        (v = self[:view_path]).kind_of?(Enumerable) ? v : [v.to_s]
      end

      def add_filter(type, fn = nil, &block)
        Filter.filters[type] << block if block_given?
        Filter.filters[type] << fn if fn
      end

      def before(fn = nil, &block)
        add_filter(:before, fn, &block)
      end

      def after(fn = nil, &block)
        add_filter(:after, fn, &block)
      end

      def helpers(*extensions, &block)
        Binding.class_eval(&block) if block_given?
        extensions.each do |extension|
          Binding.class_eval do
            include extension
            [:before, :after].each do |type|
              if extension.method_defined?(type)
                Filter.filters[type] << extension.instance_method(type)
                undef_method type
              end
            end
          end
        end
      end
    end

    class NotFound
      def self.call(env)
        Rack::Response.new(["Not Found: #{env['REQUEST_PATH']}"], 404).finish
      end
    end

    class Template

      def self.[] file, config = {}
        engine.new(file, config).find_template
      end

      def self.engine
        defined?(Tilt) ? TiltTemplate : ERBTemplate
      end

      def self.tilt?
        engine == TiltTemplate
      end

      def initialize(file, config = {})
        @file = file
        @config = config
        @config[:default_charset] ||= 'utf-8'
      end

      def mime_type
        ext = @file[/(\.\w+)?(?:\.\w+)$/, 1]
        Mime.mime_type(ext, default_mime_type)
      end

      def mime_type_with_charset
        if (m = mime_type) =~ %r!^(text/\w+|application/(?:javascript|(xhtml\+)?xml|json))$!
         "#{m}; charset=#{@config[:default_charset]}"
        else
         m
        end
      end

      def render_with_layout(scope, &block)
        content = render(scope, &block)
        if layout = scope.layout and layout_file = Dir["#{layout}{.*,}"].first
          scope.layout(false)
          Template[layout_file, @config].render_with_layout(scope) { content }
        else
          content
        end
      end

      def call(env)
        scope = Binding.new(env)
        scope.response.tap do |res|
          catch(:halt) do
            Filter.exec(:before, scope)
            res.write render_with_layout(scope)
            res['Last-Modified'] ||= ::File.mtime(@file).httpdate
            res['Content-Type']  ||= mime_type_with_charset
            res['Cache-Control'] ||= @config[:cache_control] if @config[:cache_control]
            Filter.exec(:after, scope)
          end
        end.finish
      end

      class TiltTemplate < Template
        def find_template
          (@tilt ||= Tilt[@file]) ? self : nil
        end

        def render(scope, &block)
          @tilt.new(@file).render(scope, &block)
        end

        def default_mime_type
          @tilt.default_mime_type || 'text/html'
        end
      end

      class ERBTemplate < Template
        require 'erb'

        def self.extensions(ext = nil)
          @extensions = ext if ext
          @extensions ||= %w(erb rhtml)
        end

        def find_template
          (@file =~ /\.(#{self.class.extensions.join('|')})$/) and ::File.exist?(@file) ? self : nil
        end

        def render(scope, &block)
          ERB.new(IO.read(@file)).result(scope._binding(&block))
        end

        def default_mime_type
          "text/html"
        end
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

    module CoreHelper
      def redirect(target, status=302)
        response.redirect(target, status)
        halt
      end

      def partial(file)
        if tpl_file = Dir["#{file}{.*,}"].first and template = Template[tpl_file]
          template.render(self)
        else
          IO.read(file)
        end
      end

      def layout(file = nil)
        @layout = file unless file.nil?
        @layout
      end

      def halt(*args)
        case args[0]
        when String
          response.body = [args[0]]
        when Fixnum
          response.status = args[0]
          case args[1]
          when Hash
            response.headers.merge! args[1]
            response.body = [args[2]]
          else
            response.body = [args[1]]
          end
        end
        throw :halt
      end

      def url(path = "")
        env['SCRIPT_NAME'] + (path.to_s[0,1]!='/'?'/':'') + path.to_s
      end
    end

    class Filter

      @@filters = { :before => [], :after => [] }

      def self.filters
        @@filters
      end

      def self.exec(type, scope)
        filters[type].each do |filter|
          filter.respond_to?(:bind) ? filter.bind(scope).call : scope.instance_exec(&filter)
        end
      end
    end

    class Binding
      extend Forwardable
      include CoreHelper
      include ERB::Util

      attr_reader :request, :response

      def_delegators :request, :env, :params, :session, :cookies, :logger
      def_delegators :response, :headers, :set_cookies, :delete_cookie

      def initialize(env)
        @request  = Rack::Request.new(env)
        @response = Rack::Response.new
        @response['Content-Type'] = nil
      end

      def _binding
        binding
      end
    end

  end
end
