require 'bundler/setup'

require 'rake'
require 'rake/extensiontask'
require 'rubygems/package_task'
require 'rspec/core/rake_task'
require "bundler/gem_tasks"

gem = Gem::Specification.load(File.dirname(__FILE__) + '/gloss.gemspec' )
Rake::ExtensionTask.new('gloss', gem )

Gem::PackageTask.new gem  do |pkg|
  pkg.need_zip = pkg.need_tar = false
end

RSpec::Core::RakeTask.new :spec  do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

build_gem = Rake::Task[:build].dup
task :build_gem do
  build_gem.invoke
end
Rake::Task[:build].clear

task :build do
  sh "cd", "ext/gloss", "&&", "make", "all", "&&", "cd", "-"
end

Rake::Task[:release].clear
task :release do
  [
    :build_gem,
    :'release:guard_clean',
    :'release:source_control_push',
    :'release:rubygem_push'
  ].each { |t| Rake::Task[t].invoke }
end

task :default => [:spec]
