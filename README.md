Rack Server Pages
=================

Rack middleware for serving dynamic pages with Tilt template interface.
There are no controllers or models, just only views like a jsp, asp and php!

## Features
- Render with Tilt
- Include a partial template
- Layout template
- Serve static files

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
- Gem file
- stacktrace
- Form Helper
- static generator
