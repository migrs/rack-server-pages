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
  - rack request
  - session
  - params
  - scope

  todo:

  sinatra extension:
  - layout template
  - include template
=end

module Rack
  class ServerPages
    VERSION = '0.0.1'

    def initialize(app, options = {})
      @app = app
      @path = options[:path] || '/'
      @roots = options[:root].kind_of?(Enumerable) ? options[:root] :
        (options[:root].nil? or options[:root].empty?) ? %w(views public) : [options[:root].to_s]
      @cache_control = options[:cache_control]
    end

    def call(env)
      files, req_ext = if m = env['PATH_INFO'].match(%r!^#{@path}((?:[\w-]+/)+)?(\w+)?(\.\w+)?$!)
        [Dir[@roots.map{|root|"#{root}/#{m[1]}#{m[2] || 'index'}.*"}.join("\0")], m[3]]
      end

      if files and files.size > 0
        tpl_file = files[0]
        res_ext, tpl_ext = tpl_file.match(/(\.\w+)?(\.\w+)$/).captures
        res_ext ||= req_ext

        if tpl = Tilt[tpl_ext]
          scope = Binding.new(env)
          scope.response.tap do |res|
            catch(:halt) do
              res.write tpl.new(tpl_file).render(scope)
              res['Last-Modified'] ||= ::File.mtime(tpl_file).httpdate
              res['Content-Type']  ||= Mime.mime_type(res_ext, tpl.default_mime_type)
              res['Cache-Control'] ||= @cache_control if @cache_control
            end
          end.finish
        else
          StaticFile.new(tpl_file, @cache_control).call(env)
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

      def_delegators :request, :env, :params, :session, :cookies, :logger
      def_delegators :response, :headers, :set_cookies, :delete_cookie

      def initialize(env)
        @request  = Rack::Request.new(env)
        @response = Rack::Response.new
      end

      def redirect(target, status=302)
        response.redirect(target, status)
        throw :halt
      end
    end
  end
end

module Rack::ServerPages::Binding::Extra
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
        <h2>Tilt</h2>
        <table border="0" cellpadding="3" width="600">
          <% for key, value in Tilt.mappings do %>
            <tr><td class="e"><%= key %></td><td class="v"><%= value %></td></tr>
          <% end %>
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
end
Rack::ServerPages::Binding.send(:include, Rack::ServerPages::Binding::Extra)
