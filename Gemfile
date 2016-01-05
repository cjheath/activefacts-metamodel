source 'https://rubygems.org'

gemspec

if ENV['PWD'] =~ %r{\A#{ENV['HOME']}/work}i
  $stderr.puts "Using work area gems for #{File.basename(File.dirname(__FILE__))} from activefacts-metamodel"
  gem 'activefacts-api', path: '../api'
end
