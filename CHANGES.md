CHANGES
=======

### [v0.2.0](https://github.com/migrs/rack-server-pages/releases/tag/v0.2.0) / 2024-10-19

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.1.0...v0.2.0)

  * Feature
    - Added support for Rack 3
    - Added support for paths with special and unicode characters
    - The built in `Rack::ServerPages::PHPHelper` has been removed

  * Misc
    - Replaced Travis-CI with GitHub Actions
    - Upgraded RuboCop to 1.67
    - Added support for Ruby 3.3

### [v0.1.0](https://github.com/migrs/rack-server-pages/releases/tag/v0.1.0)

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.0.6...v0.1.0)

  * Bugfix
    - Fix [#5](https://github.com/migrs/rack-server-pages/issues/5): compatibility with Rack 2.0 [@dblock](http://github.com/dblock)
    - Fix [#4](https://github.com/migrs/rack-server-pages/issues/4): did not work redirect helper

  * Misc
    - No longer tested against Ruby < 2.2
    - Added Rubocop, Ruby linter
    - Upgraded to RSpec 3.x
    - Added integration tests with Capybara
    - Tested with Tilt 2.0

### [0.0.6](https://github.com/migrs/rack-server-pages/tree/v0.0.6) / 2012-05-16

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.0.5...v0.0.6)

  * Feature
    - Passing local parameters to partial template (Tilt mode only)

### [0.0.5](https://github.com/migrs/rack-server-pages/tree/v0.0.5) / 2012-04-18

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.0.4...v0.0.5)

  * Feature
    - Handle exceptions
      - Add `config.show_exceptions` option
      - Invoke `on_error` filter when an exception is caught

  * Enhancement
    - NotFound with 404 file
        - Rack::ServerPages::NotFound['404.html']

  * Bugfix
    - Duplicated filters

### [0.0.4](https://github.com/migrs/rack-server-pages/tree/v0.0.4) / 2012-01-15

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.0.3...v0.0.4)

  * Enhancement
    - Thread safety
    - Add instance variables info in `rubyinfo`
    - Better PATH\_INFO parsing

  * Bufix
    - Didn't work `Rack::ServerPages::Template.tilt=`
    - and rename to `Rack::ServerPages::Template.use_tilt`

  * Refactor
    - Create Filter class
    - Binding setup in own class method

  * Documents
    - Filters and Helpers
    - Add [CHANGES.md](https://github.com/migrs/rack-server-pages/blob/master/CHANGES.md) (this document)


### [0.0.3](https://github.com/migrs/rack-server-pages/tree/v0.0.3) / 2012-01-06

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.0.2...v0.0.3)

  * Feature
    - Before/After Filters
    - Include Helpers

  * Enhancement
    - Binding class initialized at boot
    - `partial` accepts block
    - bundle update

  * Refactor
    - Move rubyinfo helper to other file


### [0.0.2](https://github.com/migrs/rack-server-pages/tree/v0.0.2) / 2012-01-01

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.0.1...v0.0.2)

  * Bugfix
    - Didn't launch with ERBTemplate


### [0.0.1](https://github.com/migrs/rack-server-pages/tree/v0.0.1) / 2012-01-01

  * Initial Release

  * Feature
    - Serving dynamic pages (default: ERB)
    - Serving static files
    - Tilt support (optional)
    - Include a partial template
    - Layout template
