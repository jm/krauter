require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the krauter plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

Rake::TestTask.new(:benchmark) do |t|
  t.libs << 'lib'
  t.pattern = 'performance/**/*_test.rb'
  t.verbose = true
  t.options = '-- --benchmark'
end

Rake::TestTask.new(:profile) do |t|
  t.libs << 'lib'
  t.pattern = 'performance/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the krauter plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Krauter'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
