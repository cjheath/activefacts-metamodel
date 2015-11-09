source 'https://rubygems.org'

gemspec

if ENV['PWD'] =~ %r{\A#{ENV['HOME']}/work}
  $stderr.puts "Using work area gems for #{File.basename(File.dirname(__FILE__))} from activefacts-metamodel"
  gem 'activefacts-api', path: '/Users/cjh/work/activefacts/api'
  # gem 'activefacts-api', git: 'git://github.com/cjheath/activefacts-api.git'
end
