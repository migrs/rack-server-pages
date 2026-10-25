Rack Server Pages
=================

Rack middleware and application for serving dynamic pages without controllers or models, using templates similar to JSP, ASP, and PHP. Requests map directly to files in your view directories. Built-in ERB works without extra runtime dependencies beyond Rack; Tilt and additional template engines are optional.

<https://github.com/migrs/rack-server-pages>

[![Build Status](https://github.com/migrs/rack-server-pages/actions/workflows/test.yml/badge.svg)](https://github.com/migrs/rack-server-pages/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/migrs/rack-server-pages/badge.svg?branch=master)](https://coveralls.io/github/migrs/rack-server-pages?branch=master)
[![Gem Version](https://badge.fury.io/rb/rack-server-pages.svg)](https://badge.fury.io/rb/rack-server-pages)

## Features

- Serving dynamic pages (default: ERB)
- Serving static files
- Content-versioned asset URLs with `asset_path`
- Configurable static-file caching with content-based `ETag` headers and timestamp validation
- No requirements (except Rack)
- Tilt support (optional)
- Include a partial template
- Layout template
- Before/After filters
- Handle exceptions
- Include helpers
- Integrate with any rack applications (Rails, Sinatra, etc...)
- Extremely simple and easy to use!

## Requirements

- [Ruby](https://www.ruby-lang.org/)
- [Rack](https://github.com/rack/rack)

CI tests Ruby 3.0 through 3.4 and 4.0 against Rack 2.2 and 3, including browser integration tests with headless Firefox. Selenium manages the browser driver automatically.

The test suite collects line and branch coverage with SimpleCov before loading the library, including unexecuted files under `lib/`. Run `bundle exec rake spec` and open `coverage/index.html` to inspect the local report. CI publishes `coverage/.resultset.json` to Coveralls from the Ruby 4.0 / Rack 3 job only, so compatibility jobs do not overwrite each other's reports. Coverage output is ignored by Git.

## Install

Available on [RubyGems](https://rubygems.org/gems/rack-server-pages):

```
gem install rack-server-pages
```

## Basic usage

### Run as Rack application

Create `config.ru`

```ruby
require 'rack-server-pages'
run Rack::ServerPages
```

Create `public/index.erb`

```html
<h1>Hello rack!</h1>
<p><%= Time.now %></p>
```

Finally running `rackup`

```
rackup
```

and visit <http://localhost:9292/>

Valid requests,

- <http://localhost:9292/>
- <http://localhost:9292/index>
- <http://localhost:9292/index.erb>
- <http://localhost:9292/index.html>

### Use as Rack middleware

Edit `config.ru`

```ruby
require 'rack-server-pages'
use Rack::ServerPages
run Rack::ServerPages::NotFound # or your MyApp
```

And same as above.

## Template bindings

- `CoreHelper`
  - `layout(file)`
  - `partial(file)`
  - `redirect(target, status=302)` (same as [Sinatra](http://www.sinatrarb.com/intro#Browser%20Redirect))
  - `halt(*args)` (same as [Sinatra](http://www.sinatrarb.com/intro#Halting))
  - `url(path)`
  - `asset_path(path)`

- [`Rack::Request`](https://www.rubydoc.info/gems/rack/Rack/Request)
  - `request`
  - `env`
  - `params`
  - `session`
  - `cookies`

- [`Rack::Response`](https://www.rubydoc.info/gems/rack/Rack/Response)
  - `response`
  - `headers`
  - `set_cookies`
  - `delete_cookie`

- [`ERB::Util`](https://docs.ruby-lang.org/en/master/ERB/Util.html)
  - `h` (alias for: `html_escape`)
  - `u` (alias for: `url_encode`)

## Configurations

### Rack middleware

with parameter

```ruby
use Rack::ServerPages, :view_path => 'public'
```

with block

```ruby
use Rack::ServerPages do |config|
  config.view_path = 'public'
end
```

### Rack application

with parameter

```ruby
run Rack::ServerPages[:view_path => 'public']
```

with block

```ruby
run Rack::ServerPages.new { |config|
  config.view_path = 'public'
}
```

### Options

#### `view_path`

Sets the directories searched for templates and static files, in priority order. Accepts one directory or an array; the first matching file is used.

Default: `['views', 'public']`.

```ruby
config.view_path = ['site/views', 'site/public']
```

#### `effective_path`

Limits file serving to a URL prefix and removes that prefix when resolving files. Requests outside the prefix fall through to the downstream or fallback application.

Default: `nil` (no prefix).

```ruby
config.effective_path = '/pages'
```

This serves `/pages/about.html` from `about.html` under a configured `view_path` directory.

#### `default_charset`

Sets the default charset in rendered template responses' `Content-Type` header. Does not convert file contents or change static-file headers.

Default: `'utf-8'`.

```ruby
config.default_charset = 'utf-8'
```

#### `cache_control`

Sets the default `Cache-Control` response header for rendered templates, including generated CSS. A header explicitly set by a template or filter takes precedence. Static files use `static_cache_control` instead.

Default: `nil` (no policy added).

```ruby
config.cache_control = 'private, no-store'
```

This prevents caching pages containing sensitive information.

#### `static_cache_control`

Sets the `Cache-Control` response header for static files such as CSS, JavaScript, and images. Rendered templates, including generated CSS, use `cache_control` instead.

Default: `nil` (no policy added).

```ruby
config.static_cache_control = 'public, no-cache'
```

This allows caching but requires revalidation before reuse.

#### `static_etags`

Adds a content-based `ETag` response header to static files by hashing each file with SHA-256 on each request. A matching `If-None-Match` returns an empty `304` for `GET`/`HEAD` and takes precedence over `If-Modified-Since`.

Default: `true`.

```ruby
config.static_etags = false
```

This disables content hashing, `ETag` generation, and `ETag` validation without disabling `static_timestamps` or `asset_path`.

#### `static_timestamps`

Honors `If-Modified-Since` on static requests using Rack's timestamp-based conditional handling, unless enabled `static_etags` validation takes precedence.

Default: `true`.

```ruby
config.static_timestamps = false
```

This ignores `If-Modified-Since` when deployment timestamps are unreliable. The `Last-Modified` response header and `static_etags` validation are unaffected.

#### `failure_app`

Sets a fallback Rack application for requests that do not resolve to a template or static file. When used as middleware, the downstream application takes precedence over this setting.

Default: `nil` (uses the built-in `404` response when no downstream application is supplied).

```ruby
config.failure_app = ->(_env) { [404, { 'content-type' => 'text/plain' }, ['Page not found']] }
```

#### `show_exceptions`

Controls whether template-rendering errors are raised to the caller or handled as a `500` response with `on_error` filters. Does not control a built-in error page.

Default: `nil` (raises when `RACK_ENV` is unset or `'development'`; handles errors in other environments).

```ruby
config.show_exceptions = false
```

This handles template errors instead of raising them.

### Versioned assets and browser caching

Content-based `ETag` validation and versioned asset URLs work independently. With `static_etags = true` (the default), ordinary URLs such as `/styles.css` receive `ETag` headers and support `If-None-Match` without using `asset_path`. However, validators only help when the browser makes a request; they cannot prevent reuse of an asset that the browser considers fresh. `asset_path` changes the URL when the file contents change, so a browser fetching fresh HTML requests the new asset URL instead of reusing the old one. Use both for stronger stale-asset protection.

Use `asset_path` instead of a fixed local asset URL in templates:

```erb
<link rel="stylesheet" href="<%= h asset_path('/styles.css') %>">
<script src="<%= h asset_path('/scripts/app.js') %>"></script>
<img src="<%= h asset_path('/img/logo.png') %>" alt="Logo">
```

The helper adds a SHA-256 content fingerprint, for example `/styles.css?v=...`. Changed file contents produce a new URL even when a deployment preserves file timestamps and sizes. Existing query parameters and fragments are preserved, and an existing `v` parameter is replaced. Paths are relative to the configured view paths; application mounts (`SCRIPT_NAME`) and `effective_path` are included automatically. Missing files raise `Errno::ENOENT`; external URLs and parent-directory traversal are rejected.

Configure browser revalidation explicitly:

```ruby
use Rack::ServerPages do |config|
  config.cache_control = 'private, no-cache'
  config.static_cache_control = 'public, no-cache'
end
```

Both settings default to `nil`, preserving the existing cache-policy defaults. `no-cache` permits storage but requires revalidation before reuse; use `private, no-store` instead for templates containing sensitive account or payment information. These settings do not change cache headers on the downstream application.

By default, static responses include content-based `ETag` headers, hashing the file on each request. Matching `If-None-Match` requests return an empty `304` response. When both validators are present, `If-None-Match` takes precedence over `If-Modified-Since`, so a changed file is returned for an old `ETag` even if its modification time is unchanged. Requests with only `If-Modified-Since` retain Rack's timestamp-based conditional handling.

Set `config.static_etags = false` to disable content hashing and content-based `ETag` validation. With the default timestamp-validation setting, this restores Rack's original static-file conditional handling. `static_cache_control` still applies, and `asset_path` remains available independently. See [UPGRADING](UPGRADING.md) when updating from an earlier release.

`static_timestamps` also defaults to `true`. Set `config.static_timestamps = false` to ignore timestamp-based request validation when deployment timestamps are unreliable. This does not remove the `Last-Modified` response header or disable `ETag` validation. Set both options to `false` to disable both conditional checks.

Use the helper for local images, fonts, icons, and other assets too. For URLs inside CSS, rename the stylesheet to `styles.css.erb` and render those references explicitly:

```erb
.hero { background-image: url("<%= asset_path('/img/background.svg') %>"); }
```

Continue linking to `/styles.css` through `asset_path`. The fingerprint identifies the selected source file; generated CSS must also use `cache_control = 'private, no-cache'` so changes to a referenced image are picked up even when the CSS template itself has not changed. Referenced files are not rewritten automatically, and no build pipeline is needed.

Do not set `immutable` or a long freshness lifetime for these query-versioned URLs: the middleware serves the current file, not an archive of old versions. This mechanism does not force an already-open page to reload; the new URLs take effect when it fetches fresh HTML.

### Helpers

with helpers block

```ruby
use Rack::ServerPages do |config|
  config.helpers do
    def three_times(name)
      "#{([name.to_s]*3).join(' ')}!!"
    end
  end
end
```

in view file (`.erb`)

```erb
<%= three_times('blah') %>
```

with helper module

```ruby
module SampleHelper
  def three_times(name)
    "#{([name.to_s]*3).join(' ')}!!"
  end
end

use Rack::ServerPages do |config|
  config.helpers SampleHelper
end
```

with procs

```ruby
help1 = proc do
  def three_times(name)
    "#{([name.to_s]*3).join(' ')}!!"
  end
end

help2 = proc {...}

use Rack::ServerPages do |config|
  config.helpers help1, help2
end
```

### Filters

with `before`/`after` block

```ruby
use Rack::ServerPages do |config|
  config.before do
    @title = 'Hello!'
  end

  config.after do
    Logger.new($stdout).debug('xxxx')
  end
end
```

with procs

```ruby
proc1 = proc { @name = 'Jonny' }
proc2 = proc { @age = 24 }
proc3 = proc { Logger.new($stdout).debug('xxxx') }

use Rack::ServerPages do |config|
  config.before proc1, proc2
  config.after proc3
end
```

if you define a `before`/`after` method in a helper module, it will be treated as a filter

```ruby
module SampleHelper
  def before
    @title = 'Hello!'
  end

  def three_times(name)
    "#{([name.to_s]*3).join(' ')}!!"
  end
end

use Rack::ServerPages do |config|
  config.helpers SampleHelper
end
```

in view file

```erb
<%= three_times(@title) %>
```

### Rendering a template with `halt`

`partial` returns a rendered string, so pass its result to `halt` as the response body. For example, create `views/forbidden.html.erb`:

```erb
<h1><%= 'Forbidden' %></h1>
```

Inside a `before` filter, helper, or template, return that page with the desired status and content type:

```ruby
halt 403, { Rack::CONTENT_TYPE => 'text/html; charset=utf-8' }, partial('views/forbidden.html')
```

Place the call inside your existing validation or authorization check. `partial` takes a filesystem path relative to the working directory, or an absolute path; it does not search `view_path` automatically. Omitting the final `.erb` suffix lets it find the template. `halt` skips normal page rendering, so automatic layouts are not applied to this response. The example works with both built-in ERB and Tilt.

## Tilt support
[Tilt](https://github.com/rtomayko/tilt) is a generic interface to multiple Ruby template engines. To use it, add Tilt and the desired engines to your dependencies, then explicitly require them:

Tilt is selected only when its template lookup API is available. A `Tilt` namespace created by another dependency does not enable it or force it to load. Loading Tilt later enables it for subsequent requests unless you have explicitly disabled it with `Rack::ServerPages::Template.use_tilt(false)`.

```ruby
require 'rack-server-pages'
require 'tilt'
require 'rdiscount' # markdown library
run Rack::ServerPages
```

If your application uses `Bundler.require`, the equivalent `Gemfile` entries are:

```ruby
gem 'tilt', require: 'tilt'
gem 'rdiscount', require: 'rdiscount'
```

### [Markdown](http://daringfireball.net/projects/markdown/)

`views/article.html.md`

```markdown
A First Level Header
====================

A Second Level Header
---------------------

Now is the time for all good men to come to
the aid of their country. This is just a
regular paragraph.

### Header 3

> This is a blockquote.
> Thank you

[source](http://github.com/migrs/rack-server-pages)
```

<http://localhost:9292/article.html>

```html
<h1>A First Level Header</h1>

<h2>A Second Level Header</h2>

<p>Now is the time for all good men to come to
the aid of their country. This is just a
regular paragraph.</p>

<h3>Header 3</h3>

<blockquote><p>This is a blockquote.
Thank you</p></blockquote>

<p><a href="http://github.com/migrs/rack-server-pages">source</a></p>
```


### [Slim](http://slim-lang.com/)

`views/about.html.slim`

```slim
doctype html
html
  head
    title Slim Core Example
    meta name="keywords" content="template language"

  body
    h1 Markup examples

    div id="content" class="example1"
      p Nest by indentation
```

<http://localhost:9292/about.html>

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Slim Core Example</title>
    <meta content="template language" name="keywords" />
  </head>
  <body>
    <h1>Markup examples</h1>
    <div class="example1" id="content">
      <p>Nest by indentation</p>
    </div>
  </body>
</html>
```

### [Sass](http://sass-lang.com/)

`views/betty.css.sass`

```sass
$blue: #3bbfce
$margin: 16px

.content-navigation
  border-color: $blue
  color: darken($blue, 9%)

.border
  padding: $margin / 2
  margin: $margin / 2
  border-color: $blue
```

<http://localhost:9292/betty.css>

```css
.content-navigation {
  border-color: #3bbfce;
  color: #2ca2af; }

.border {
  padding: 8px;
  margin: 8px;
  border-color: #3bbfce; }
```

### [Builder](http://builder.rubyforge.org/)

`views/contact.xml.builder`

```ruby
xml.instruct!
xml.result do |result|
  result.name "John"
  result.phone "910-1974"
end
```

<http://localhost:9292/contact.xml>

```xml
<result>
  <name>John</name>
  <phone>910-1974</phone>
</result>
```

### [CoffeeScript](http://jashkenas.github.com/coffee-script/)

`views/script.js.coffee`

```coffee
number   = 42
opposite = true

number = -42 if opposite

square = (x) -> x * x

list = [1, 2, 3, 4, 5]

math =
  root:   Math.sqrt
  square: square
  cube:   (x) -> x * square x
```

<http://localhost:9292/script.js>

```javascript
(function() {
  var list, math, number, opposite, square;

  number = 42;

  opposite = true;

  if (opposite) number = -42;

  square = function(x) {
    return x * x;
  };

  list = [1, 2, 3, 4, 5];

  math = {
    root: Math.sqrt,
    square: square,
    cube: function(x) {
      return x * square(x);
    }
  };

}).call(this);
```

see more <http://localhost:9292/examples/>

## Integrate with Rack applications

At first, create sample file: `public/hello.erb` or `views/hello.html.erb`

```html
<p>Hello Rack Server Pages!</p>
<p><%= Time.now %></p>
```

### Rails

Add the middleware inside your application configuration in `config/application.rb`:

```ruby
config.middleware.use Rack::ServerPages
```

Start Rails:

```
rails s
```

- <http://localhost:3000/> is Rails response
- <http://localhost:3000/hello> is Rack Server Pages response

### Sinatra

Create `sinatra_sample.rb`

```ruby
require 'sinatra'
require 'rack-server-pages'

use Rack::ServerPages

get '/' do
  '<p>Hello Sinatra!</p>'
end
```


And run

```
ruby sinatra_sample.rb
```

- <http://localhost:4567/> is Sinatra response
- <http://localhost:4567/hello> is Rack Server Pages response

## Customization

### Customize file extension associations

#### e.g. `.php` as ERB

`ERBTemplate` (default)

```ruby
Rack::ServerPages::Template::ERBTemplate.extensions << 'php'
```

`TiltTemplate` (see. [Template Mappings](http://github.com/rtomayko/tilt))

```ruby
Tilt.register Tilt::ERBTemplate, 'php'
```

And create `public/info.php` :)

```erb
<%= phpinfo(); %>
```

<http://localhost:9292/info.php>

## Development

Clone the repository and install its development dependencies. RedCloth and BlueCloth are legacy optional test engines; the C17 build options let them compile when Ruby defaults to C23:

```sh
bundle config set --local build.RedCloth --with-cflags=-std=gnu17
bundle config set --local build.bluecloth --with-cflags=-std=gnu17
bundle install
MOZ_HEADLESS=1 bundle exec rake
```

The default task runs lint and the full suite. Browser examples require Firefox; Selenium manages its driver. Run `bundle exec rake spec` for only the tests.

Run the included application with `bundle exec rackup` and visit <http://localhost:9292/> or <http://localhost:9292/examples/> for local examples. There is no maintained hosted demo.

## License

[rack-server-pages](http://github.com/migrs/rack-server-pages) is Copyright (c) 2012-2016 [Masato Igarashi](http://github.com/migrs)(@[migrs](http://twitter.com/migrs)) and Contributors.

Distributed under the [MIT license](LICENSE.md).
