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
  # sh "echo 0 && pwd && ls && echo '...'"
  sh "ls", "ext"
  sh "cd", "ext/gloss"
  sh "echo 1 && pwd && ls && echo '...'"
  # sh "make", "all"
  # sh "echo 2 && pwd && ls && echo '...'"
  # sh "cd", "-"
  # sh "echo 3 && pwd && ls && echo '...'"
end

task build: [:build_gem]

task default: [:spec]
