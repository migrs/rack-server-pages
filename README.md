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

- CoreHelper
  - layout(file)
  - partial(file)
  - redirect(target, status=302) (same as [Sinatra](http://www.sinatrarb.com/intro#Browser%20Redirect))
  - halt(\*args) (same as [Sinatra](http://www.sinatrarb.com/intro#Halting))
  - url(path)

- [Rack::Request](https://www.rubydoc.info/gems/rack/Rack/Request)
  - request
  - env
  - params
  - session
  - cookies

- [Rack::Response](https://www.rubydoc.info/gems/rack/Rack/Response)
  - response
  - headers
  - set\_cookies
  - delete\_cookie

- [ERB::Util](https://docs.ruby-lang.org/en/master/ERB/Util.html)
  - h (alias for: html\_escape)
  - u (alias for: url\_encode)

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

- view\_path
  - Views folders to load templates from.
  - default: [views, public]

- effective\_path
  - default: nil

- default\_charset
  - default: utf-8

- cache\_control
  - default: nil

- failure\_app
  - default: nil

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

in view file (erb)

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

with before/after block

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

if you define before/after method in helper module, it will be treated as filters

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

Inside a before filter, helper, or template, return that page with the desired status and content type:

```ruby
halt 403, { Rack::CONTENT_TYPE => 'text/html; charset=utf-8' }, partial('views/forbidden.html')
```

Place the call inside your existing validation or authorization check. `partial` takes a filesystem path relative to the working directory, or an absolute path; it does not search `view_path` automatically. Omitting the final `.erb` suffix lets it find the template. `halt` skips normal page rendering, so automatic layouts are not applied to this response. The example works with both built-in ERB and Tilt.

## Tilt support
[Tilt](https://github.com/rtomayko/tilt) is a generic interface to multiple Ruby template engines. To use it, add Tilt and the desired engines to your dependencies, then explicitly require them:

```ruby
require 'rack-server-pages'
require 'tilt'
require 'rdiscount' # markdown library
run Rack::ServerPages
```

If your application uses `Bundler.require`, the equivalent Gemfile entries are:

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

#### e.g. .php as ERB

ERBTemplate (default)

```ruby
Rack::ServerPages::Template::ERBTemplate.extensions << 'php'
```

TiltTemplate (see. [Template Mappings](http://github.com/rtomayko/tilt))

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
