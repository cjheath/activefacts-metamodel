source 'https://rubygems.org'

gemspec

gem 'byebug'
gem 'rubyzip'

this_file = File.absolute_path(__FILE__)
if this_file =~ %r{\A#{ENV['HOME']}}i
  dir = File.dirname(File.dirname(this_file))
  $stderr.puts "Using work area gems in #{dir} from activefacts-factil"
  gem 'activefacts-api', path: dir+'/api'
  gem 'activefacts-metamodel', path: dir+'/metamodel'
  gem 'activefacts-cql', path: dir+'/cql'
  gem 'activefacts-compositions', path: dir+'/compositions'
end
