require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "pp"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Bump gem version patch number"
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

desc "Generate new CQL from the ORM file (to verify version similarity)"
task :validation do
  # Note: Import from ORM is broken on the implicit derivations in constraints, and the result is unstable.
  # This means that SOME PATCHES WILL FAIL
  system "bundle exec afgen --cql orm/Metamodel.orm > Metamodel.orm.cql"
  system "patch < orm/Metamodel.cql.diffs"
  system "bundle exec afgen --cql cql/Metamodel.cql 2>Metamodel.cql.errors >Metamodel.cql.cql"
  system "diff -b -C 1  Metamodel.cql.cql Metamodel.orm.cql | tee Metamodel.cql.diffs"
end

# This patch exists because there are some features of the CQL that we
# can't represent in the ORM, and some features in the ORM that we don't
# want to represent in the CQL.
desc "When you're satisfied that the CQL-generated ORM is close enough, make a new patch"
task :remake_orm_patch do
  system "diff -C1 Metamodel.orm.cql.orig  Metamodel.orm.cql > orm/Metamodel.cql.diffs"
end

desc "Generate new Ruby from the CQL file"
task :ruby do
  system %q{
    bundle exec schema_compositor --binary --ruby=scope=ActiveFacts cql/Metamodel.cql > metamodel.rb &&
    diff -ub lib/activefacts/metamodel/metamodel.rb metamodel.rb
  }
end
