require 'bundler/setup'

require 'rake'
require 'rake/extensiontask'
require 'rubygems/package_task'
require 'rspec/core/rake_task'
require "bundler/gem_tasks"

gem = Gem::Specification.load(File.dirname(__FILE__) + '/hrb.gemspec' )
Rake::ExtensionTask.new('hrb', gem )

Gem::PackageTask.new gem  do |pkg|
  pkg.need_zip = pkg.need_tar = false
end

RSpec::Core::RakeTask.new :spec  do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => [:spec]
