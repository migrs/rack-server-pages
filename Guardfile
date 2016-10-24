# A sample Guardfile
# More info at https://github.com/guard/guard#readme
group 'backend' do
  guard 'bundler' do
    watch('Gemfile')
    # Uncomment next line if Gemfile contain `gemspec' command
    # watch(/^.+\.gemspec/)
  end
  guard 'rspec', cli: '--color --format nested', bundler: true do
    watch(%r{^lib/([\w/]+)\.rb}) { |m| "spec/lib/#{m[1]}_spec.rb" }

    watch(%r{^spec/(.+)\_spec.rb}) { |m| "spec/#{m[1]}_spec.rb" }

    watch('spec/spec_helper.rb') { 'bundle exec rake spec' }
  end
end
