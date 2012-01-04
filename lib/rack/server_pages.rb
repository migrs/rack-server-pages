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

        if template = Template[file]
          scope = Binding.new(env)
          scope.response.tap do |res|
            catch(:halt) do
              res.write template.render_with_layout(scope)
              res['Last-Modified'] ||= ::File.mtime(file).httpdate
              res['Content-Type']  ||= template.mime_type_with_charset(@config.default_charset)
              res['Cache-Control'] ||= @config.cache_control if @config.cache_control
            end
          end.finish
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
    end

    class NotFound
      def self.call(env)
        Rack::Response.new(["Not Found: #{env['REQUEST_PATH']}"], 404).finish
      end
    end

    class Template
      def self.[] file
        engine.new(file).find_template
      end

      def self.engine
        defined?(Tilt) ? TiltTemplate : ERBTemplate
      end

      def self.tilt?
        engine == TiltTemplate
      end

      def initialize(file)
        @file = file
      end

      def mime_type
        ext = @file[/(\.\w+)?(?:\.\w+)$/, 1]
        Mime.mime_type(ext, default_mime_type)
      end

      def mime_type_with_charset(charset)
        if (m = mime_type) =~ %r!^(text/\w+|application/(?:javascript|(xhtml\+)?xml|json))$!
         "#{m}; charset=#{charset}"
        else
         m
        end
      end

      def render_with_layout(scope, &block)
        content = render(scope, &block)
        if layout = scope.layout and layout_file = Dir["#{layout}{.*,}"].first
          scope.layout(false)
          Template[layout_file].render_with_layout(scope) { content }
        else
          content
        end
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

module Rack::ServerPages::Binding::Extra
  require 'erb'
  def rubyinfo
    ERB.new(<<-RUBYINFO).result(binding)
    <html><head>
    <style type="text/css"><!--
    body {background-color: #ffffff; color: #000000;}
    body, td, th, h1, h2 {font-family: sans-serif;}
    pre {margin: 0px; font-family: monospace;}
    a:link {color: #000099; text-decoration: none; background-color: #ffffff;}
    a:hover {text-decoration: underline;}
    table {border-collapse: collapse;}
    .center {text-align: center;}
    .center table { margin-left: auto; margin-right: auto; text-align: left;}
    .center th { text-align: center !important; }
    td, th { border: 1px solid #000000; font-size: 75%; vertical-align: baseline;}
    h1 {font-size: 150%;}
    h2 {font-size: 125%;}
    .p {text-align: left;}
    .e {background-color: #ccccff; font-weight: bold; color: #000000;}
    .h {background-color: #9999cc; font-weight: bold; color: #000000;}
    .v {background-color: #cccccc; color: #000000;}
    i {color: #666666; background-color: #cccccc;}
    img {float: right; border: 0px;}
    hr {width: 600px; background-color: #cccccc; border: 0px; height: 1px; color: #000000;}
    //--></style>
    <title>rubyinfo()</title>
    </head>
    <body>
      <div class="center">
        <table border="0" cellpadding="3" width="600">
          <tr class="h">
            <td>
            <h1 class="p">Rack Server Pages Version <%= Rack::ServerPages::VERSION%></h1>
            </td>
          </tr>
        </table>
        <br />
        <h2>Rack Environment</h2>
        <table border="0" cellpadding="3" width="600">
          <tr class="h"><th>Variable</th><th>Value</th></tr>
          <% for key, value in env do %>
            <tr><td class="e"><%= key %></td><td class="v"><%= value %></td></tr>
          <% end %>
        </table>
        <h2>Ruby</h2>
        <table border="0" cellpadding="3" width="600">
          <tr><td class="e">RUBY_VERSION</td><td class="v"><%= RUBY_VERSION %></td></tr>
          <tr><td class="e">RUBY_PATCHLEVEL</td><td class="v"><%= RUBY_PATCHLEVEL %></td></tr>
          <tr><td class="e">RUBY_RELEASE_DATE</td><td class="v"><%= RUBY_RELEASE_DATE %></td></tr>
          <tr><td class="e">RUBY_PLATFORM</td><td class="v"><%= RUBY_PLATFORM %></td></tr>
        </table>
        <h2>Environment</h2>
        <table border="0" cellpadding="3" width="600">
          <tr class="h"><th>Variable</th><th>Value</th></tr>
          <% for key, value in ENV do %>
            <tr><td class="e"><%= key %></td><td class="v"><%= value %></td></tr>
          <% end %>
        </table>
        <% if defined?(Tilt) %>
        <h2>Tilt</h2>
        <table border="0" cellpadding="3" width="600">
          <% for key, value in Tilt.mappings do %>
            <tr><td class="e"><%= key %></td><td class="v"><%= value %></td></tr>
          <% end %>
        </table>
        <% else %>
        <h2>ERB Template</h2>
        <table border="0" cellpadding="3" width="600">
          <tr><td class="e">extensions</td><td class="v"><%=Rack::ServerPages::Template::ERBTemplate.extensions.join(', ')%></td></tr>
        </table>
        <% end %>
        <h2>Binding</h2>
        <table border="0" cellpadding="3" width="600">
          <tr><td class="e">methods</td><td class="v"><%= (methods - Object.methods).join(', ') %></td></tr>
        </table>
        <h2>License</h2>
        <table border="0" cellpadding="3" width="600">
        <tr class="v"><td>
        <p>
        MIT License
        </p>
        </td></tr>
        </table><br />
      </div>
    </body>
    </html>
    RUBYINFO
  end
  alias phpinfo rubyinfo # just a joke :)
end
Rack::ServerPages::Binding.send(:include, Rack::ServerPages::Binding::Extra)
