require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "pp"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :bump do
  path = File.expand_path('../lib/activefacts/metamodel/version.rb', __FILE__)
  lines = File.open(path) do |fp| fp.readlines; end
  File.open(path, "w") do |fp|
    fp.write(
      lines.map do |line|
	line.gsub(/(VERSION *= *"[0-9.]*\.)([0-9]+)"\n/) do
	  version = "#{$1}#{$2.to_i+1}"
	  puts "Version bumped to #{version}\""
	  version+"\"\n"
	end
      end*''
    )
  end
end
