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

task :build_gem do
  sh "ls"
  sh "cd", "ext/gloss"
  sh "ls"
  sh "make", "all"
  sh "cd", "-"
  sh "ls"
end

task build: [:build_gem]

task default: [:spec]
