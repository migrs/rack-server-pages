Rack Server Pages
=================

Rack middleware and application for serving dynamic pages.  
There are no controllers or models, just only views like a jsp, asp and php!

<http://github.com/migrs/rack-server-pages>

## Features

- Serving dynamic pages (default: ERB)
- Serving static files
- No requirements (except Rack)
- Tilt support (optional)
- Include a partial template
- Layout template
- Integrate with any rack applications (Rails, Sinatra, etc...)
- Extremely simple and easy to use!

## Requirements

- [Ruby](http://ruby-lang.org/) 1.8.7 or 1.9.x
- [Rack](http://github.com/rack/rack)

## Install

    gem install rack-server-pages

## Basic usage

### Run as Rack application

Create `config.ru`

    require 'rack-server-pages'
    run Rack::ServerPages

Create `public/index.erb`

    <h1>Hello rack!</h1>
    <p><%= Time.now %></p>

Finally running `rackup`

    rackup

and visit <http://localhost:9292/>

### Use as Rack middleware

Edit `config.ru`

    require 'rack-server-pages'
    use Rack::ServerPages
    run Rack::ServerPages::NotFound # or your MyApp

And same as above.

## Template bindings

- CoreHelper
  - layout(file)
  - partial(file)
  - redirect(target, status=302) (same as [Sinatra](http://www.sinatrarb.com/intro#Browser%20Redirect))
  - halt(\*args) (same as [Sinatra](http://www.sinatrarb.com/intro#Halting))
  - url(path)

- [Rack::Request](http://rack.rubyforge.org/doc/Rack/Request.html)
  - request
  - env
  - params
  - session
  - cookies
  - logger

- [Rack::Response](http://rack.rubyforge.org/doc/Rack/Response.html)
  - response
  - headers
  - set\_cookies
  - delete\_cookie

- [ERB::Util](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/erb/rdoc/ERB/Util.html)
  - h (alias for: html\_escape)
  - u (alias for: url\_encode)

## Configurations

### Rack middleware

with parameter

    use Rack::ServerPages, :view_path => 'public'

with block

    use Rack::ServerPages do |config|
      config.view_path = 'public'
    end

### Rack application

with parameter

    run Rack::ServerPages[:view_path => 'public']

with block

    run Rack::ServerPages.new { |config|
      config.view_path = 'public'
    }

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


## Tilt support
[Tilt](http://github.com/rtomayko/tilt) is generic interface to multiple Ruby template engines.  
If you want to use Tilt, just `require 'tilt'` and require template engine libraries that you want.

    require 'rack-server-pages'
    require 'tilt'
    require 'rdiscount' # markdown library
    run Rack::ServerPages

see <http://localhost:9292/examples/>

## Integrate with Rack applications

### Rails

`config/environment.rb`

    config.middleware.use Rack::ServerPages

### Sinatra / Padrino

## Customize

### Customize file extension associations

#### e.g. .php as ERB

ERBTemplate (default)

    Rack::ServerPages::Template::ERBTemplate.extensions << 'php'

TiltTemplate (see. [Template Mappings](http://github.com/rtomayko/tilt))

    Tilt.register Tilt::ERBTemplate, 'php'

## ToDo

### Implements
- Before/After filter
- Support Helpers
- Static file generator (for designer)

### Tasks
  - Tutorials
    - for PHP user
    - for Designer
    - for Windows user
  - More documents
    - Deployment using apache / passenger / nginx
  - Complete Tilt examples
  - Philosophy
  - Benchmark

## License
[rack-server-pages](http://github.com/migrs/rack-server-pages) is Copyright (c) 2011 [Masato Igarashi](http://m.igrs.jp/)(@[migrs](http://twitter.com/migrs)) and distributed under the [MIT license](http://www.opensource.org/licenses/mit-license).

### Info & Contacts
- <http://m.igrs.jp/>
- <http://github.com/migrs>
- <http://twitter.com/migrs>
