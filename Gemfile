source :rubygems

gem 'rake'
gem 'rack-contrib'
gem 'tilt'

gem 'rdiscount'

group :development do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'rb-readline'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end

group :test do
  gem 'rack-test', :require => 'rack/test'
  gem 'rspec'
end

group :development, :test do
  gem 'tapp'
  gem 'ruby-debug19', :require => 'ruby-debug'
end
