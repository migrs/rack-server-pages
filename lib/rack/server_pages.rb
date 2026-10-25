# -*- encoding: utf-8 -*-
require 'rack'
require 'rack/utils'
require 'rack/mime'
require 'time'
require 'forwardable'
require 'digest/sha2'

module Rack
  class ServerPages
    class << self
      def call(env)
        new.call(env)
      end

      def [](options = {}, &block)
        new(nil, options, &block)
      end
    end

    def initialize(app = nil, options = {})
      @config = Config.new(*options)
      yield @config if block_given?
      @app = app || @config.failure_app || NotFound

      @config.filter.merge_from_helpers(@config.helpers)
      @binding = Binding.extended_class(@config.helpers)

      @path_regex = %r{(?u)^#{@config.effective_path}/((?:[^\/]+/)+)?([\w][^\/]*?\w)?(\.\w+)?$}
    end

    def call(env)
      dup.serving(env)
    end

    def serving(env)
      path_info = CGI.unescape(env['PATH_INFO'])
      files = find_template_files(path_info)
      if files.nil? || files.empty?
        @app
      else
        file = select_template_file(files)
        (tpl = Template[file]) ? server_page(tpl) : static_file(file, path_info)
      end.call(env)
    end

    module StaticFiles
      def static_file(file, path_info)
        root = file.split(path_info).first
        return Rack::Files.new(root) unless ::File.file?(file) && ::File.readable?(file)

        headers = static_headers(file)
        files = Rack::Files.new(root, headers)
        lambda do |env|
          if @config.static_etags && %w[GET HEAD].include?(env['REQUEST_METHOD']) && matching_etag?(env['HTTP_IF_NONE_MATCH'], headers[Rack::ETAG])
            [304, headers.dup, []]
          else
            files.call(static_request_env(env))
          end
        end
      end

      private

      def static_request_env(env)
        # If-None-Match takes precedence over If-Modified-Since.
        ignore_modified_since = !@config.static_timestamps || (@config.static_etags && env.key?('HTTP_IF_NONE_MATCH'))
        ignore_modified_since ? env.merge('HTTP_IF_MODIFIED_SINCE' => nil) : env
      end

      def static_headers(file)
        headers = @config.static_etags ? { Rack::ETAG => %("#{Digest::SHA256.file(file).hexdigest}") } : {}
        @config.static_cache_control ? headers.merge(Rack::CACHE_CONTROL => @config.static_cache_control) : headers
      end

      def matching_etag?(condition, etag)
        condition.to_s.split(',').any? do |candidate|
          candidate = candidate.strip.sub(%r{\AW/}, '')
          candidate == '*' || candidate == etag
        end
      end
    end

    include StaticFiles

    def find_template_files(path_info)
      if m = path_info.match(@path_regex)
        @config.view_paths.inject([]) do |files, path|
          files.concat Dir["#{path}/#{m[1]}#{m[2] || 'index'}#{m[3]}{.*,}"].select { |s| s.include?('.') }
        end
      end
    end

    def select_template_file(files)
      files.first
    end

    def build_response(template, scope)
      scope.response.tap do |response|
        response.write template.render_with_layout(scope)
        response['Last-Modified'] ||= ::File.mtime(template.file).httpdate
        response['Content-Type']  ||= template.mime_type_with_charset(@config.default_charset)
        response['Cache-Control'] ||= @config.cache_control if @config.cache_control
      end
    end

    def server_page(template)
      lambda do |env|
        @binding.new(env, self).tap do |scope|
          catch(:halt) do
            begin
              @config.filter.invoke(scope, :before)
              build_response(template, scope)
            rescue
              if @config.show_exceptions?
                raise $!
              else
                scope.response.status = 500
                scope.response['Content-Type'] ||= 'text/html'
                @config.filter.invoke(scope, :on_error)
              end
            ensure
              @config.filter.invoke(scope, :after)
            end
          end
        end.response.finish
      end
    end

    module AssetPaths
      def asset_path(path)
        path, fragment = path.to_s.split('#', 2)
        path, query = path.to_s.split('?', 2)
        path, file = asset_file(path.to_s)
        query = Rack::Utils.parse_query(query)
        query['v'] = Digest::SHA256.file(file).hexdigest
        "#{path}?#{Rack::Utils.build_query(query)}#{fragment && "##{fragment}"}"
      end

      private

      def asset_file(path)
        raise ArgumentError, 'asset_path requires a local asset path without parent-directory traversal' unless valid_asset_path?(CGI.unescape(path))

        path = "#{@config.effective_path}/#{path.sub(%r{\A/}, '')}"
        file = select_template_file(find_template_files(CGI.unescape(path)) || [])
        raise Errno::ENOENT, path unless file && ::File.file?(file)

        [path, file]
      end

      def valid_asset_path?(path)
        !path.empty? && (path !~ %r{\A(?:[a-z][a-z0-9+.-]*:|//)}i) &&
          !path.split('/').include?('..') && !path.include?("\0")
      end
    end

    include AssetPaths

    class Filter
      TYPES = [:before, :after, :on_error].freeze
      TYPES.each do |type|
        define_method(type) { |*fn, &block| add(type, *fn, &block) }
      end

      def initialize
        @filters = Hash[[TYPES, Array.new(TYPES.size) { [] }].transpose]
      end

      def [](type)
        @filters[type]
      end

      def merge(other)
        TYPES.each { |type| @filters[type].concat other[type] }
      end

      def merge_from_helpers(helpers)
        merge(self.class.extract_filters_from_helpers(helpers))
      end

      def add(type, *args, &block)
        @filters[type] << block if block_given?
        @filters[type].concat args unless args.empty?
      end

      def invoke(scope, type)
        @filters[type].each { |f| f.respond_to?(:bind) ? f.bind(scope).call : scope.instance_exec(&f) }
      end

      def self.extract_filters_from_helpers(helpers)
        new.tap do |filter|
          helpers.each do |helper|
            next unless helper.is_a? Module
            TYPES.each do |type|
              if helper.method_defined?(type)
                filter[type] << helper.instance_method(type)
                helper.class_eval { undef :"#{type}" }
              end
            end
          end
        end
      end
    end

    class Config < Hash
      extend Forwardable

      def self.hash_accessor(*names)
        names.each do |name|
          define_method("#{name}=") { |v| self[name] = v }
          define_method(name) { self[name] }
        end
      end

      hash_accessor :view_path, :effective_path, :cache_control, :static_cache_control, :static_etags, :static_timestamps,
                    :default_charset, :failure_app, :show_exceptions

      attr_reader :filter

      def_delegators :filter, *Filter::TYPES

      def initialize
        super
        self[:default_charset] ||= 'utf-8'
        self[:view_path] ||= %w(views public)
        self[:static_etags] = true
        self[:static_timestamps] = true
        @helpers = []
        @filter  = Filter.new
      end

      def show_exceptions?
        if self[:show_exceptions].nil?
          ENV['RACK_ENV'].nil? || (ENV['RACK_ENV'] == 'development')
        else
          self[:show_exceptions]
        end
      end

      def view_paths
        (v = self[:view_path]).is_a?(Enumerable) ? v : [v.to_s]
      end

      def helpers(*args, &block)
        @helpers << block if block_given?
        @helpers.concat args unless args.empty?
        @helpers
      end
    end

    class Template
      class << self
        def [](file)
          engine.new(file).find_template
        end

        def engine
          tilt? ? TiltTemplate : ERBTemplate
        end

        def tilt?
          @use_tilt != false && !!defined?(Tilt) && Tilt.respond_to?(:[])
        end

        def use_tilt(bool = true)
          @use_tilt = !!bool
        end
      end

      attr_reader :file

      def initialize(file)
        @file = file
      end

      def mime_type
        ext = @file[/(\.\w+)?(?:\.\w+)$/, 1]
        Mime.mime_type(ext, default_mime_type)
      end

      def mime_type_with_charset(charset = 'utf-8')
        if (m = mime_type) =~ %r{^(text/\w+|application/(?:javascript|(xhtml\+)?xml|json))$}
          "#{m}; charset=#{charset}"
        else
          m
        end
      end

      def render_with_layout(scope, locals = {}, &block)
        content = render(scope, locals, &block)
        if (layout = scope.layout) && (layout_file = Dir["#{layout}{.*,}"].first)
          scope.layout(false)
          Template[layout_file].render_with_layout(scope) { content }
        else
          content
        end
      end

      class TiltTemplate < Template
        def find_template
          @tilt ||= Tilt[@file]
          @tilt ? self : nil
        end

        def render(scope, locals = {}, &block)
          @tilt.new(@file).render(scope, locals, &block)
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
          (@file =~ /\.(#{self.class.extensions.join('|')})$/) && ::File.exist?(@file) ? self : nil
        end

        def render(scope, _locals = {}, &block)
          ## TODO: support locals
          ERB.new(IO.read(@file)).result(scope._binding(&block))
        end

        def default_mime_type
          'text/html'
        end
      end
    end

    class NotFound
      def self.[](file)
        ::File.file?(file) ? proc { Rack::Response.new([::File.read(file)], 404).finish } : self
      end

      def self.call(env)
        Rack::Response.new(["Not Found: #{env['PATH_INFO']}"], 404).finish
      end
    end

    module CoreHelper
      def asset_path(path)
        url(@server_pages.asset_path(path))
      end

      def redirect(target, status = 302)
        response.redirect(target, status)
        halt
      end

      def partial(file, locals = {}, &block)
        if (tpl_file = Dir["#{file}{.*,}"].first) && (template = Template[tpl_file])
          template.render(self, locals, &block)
        else
          IO.read(file)
        end
      end

      def layout(file = nil)
        @layout = file unless file.nil?
        @layout
      end

      def halt(*args)
        if args[0].is_a? Integer
          response.headers.merge! args[1] if (a1_is_h = args[1].is_a? Hash)
          response.body = [a1_is_h ? args[2] : args[1]]
          response.status = args[0]
        elsif args[0]
          response.body = [args[0]]
        end
        throw :halt
      end

      def url(path = '')
        env['SCRIPT_NAME'] + (path.to_s[0, 1] != '/' ? '/' : '') + path.to_s
      end
    end

    class Binding
      extend Forwardable
      include CoreHelper
      include ERB::Util

      attr_reader :request, :response

      def_delegators :request, :env, :params, :session, :cookies
      def_delegators :response, :headers, :set_cookies, :delete_cookie

      class << self
        def extended_class(helpers)
          Class.new(self).tap { |k| k.setup(helpers) }
        end

        def setup(helpers)
          helpers.each do |helper|
            helper.is_a?(Module) ? class_eval { include helper } : class_eval(&helper)
          end
        end
      end

      def initialize(env, server_pages = nil)
        @request  = Rack::Request.new(env)
        @response = Rack::Response.new
        @server_pages = server_pages
        # @response['Content-Type'] = nil
      end

      def _binding
        binding
      end
    end
  end
end
