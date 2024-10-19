<html>
 <head>
  <style type="text/css">
   <!--
    body {background-color: #ffffff; color: #000000;}
    body, td, th, h1, h2 {font-family: sans-serif;}
    pre {margin: 0px; font-family: monospace;}
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
   //-->
  </style>
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
    <% for key, value in (Tilt.respond_to?(:mappings) ? Tilt.mappings : Tilt.lazy_map) do %>
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
    <tr><td class="e">variables</td><td class="v"><%= (instance_variables).join(', ') %></td></tr>
    <tr><td class="e">methods</td><td class="v"><%= (methods - Object.methods).join(', ') %></td></tr>
   </table>
   <h2>License</h2>
   <table border="0" cellpadding="3" width="600">
    <tr class="v">
     <td>
      <p>
       <a href="http://github.com/migrs/rack-server-pages">rack-server-pages</a> is Copyright (c) 2012 <a href="http://github.com/migrs">Masato Igarashi</a>(@<a href="http://twitter.com/migrs">migrs</a>) and distributed under the <a href="http://www.opensource.org/licenses/mit-license">MIT license</a>.
      </p>
     </td>
    </tr>
   </table>
   <br />
  </div>
 </body>
</html>
