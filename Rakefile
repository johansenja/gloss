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

task :build do
  sh "cd", "ext/gloss", "&&", "make", "all", "&&", "cd", "-"
end

task :default => [:spec]
