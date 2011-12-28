Rack Server Pages
=================

Rack middleware for serving dynamic pages.
There are no controllers or models, just only views like a jsp, asp and php!

## Features
- Serving dynamic pages (default: ERB)
- Serving static files
- No requirements (except Rack)
- Tilt Support (optional)
- Include a partial template
- Layout template
- Integrate with any rack applications (Rails, Sinatra, etc...)

## Install
```sh
gem install rack-server-pages
```

## Basic usage
```
config.ru
public/index.erb
```

`config.ru`
```ruby
require 'rack-server-pages'
use Rack::ServerPages
run lambda {|e| [404, {'Content-Type' => 'text/html'}, ['Not Found']]}
```

`public/index.erb`
```eruby
<h1>Hello rack!</h1>
<p><%= Time.now %></p>
```

use Rack::ServerPages
run lambda {|e| [404, {'Content-Type' => 'text/html'}, ['Not Found']]}

## Done
- Rack::URLMap
## ToDo
- Before/After filter
- Exeption stacktrace
- Form Helpers
- Static file generator
