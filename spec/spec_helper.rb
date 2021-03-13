require "gloss"
require "fileutils"
require_relative "support"

TESTING_DIR = "./tmp"

RSpec.configure do |config|
  config.before(:suite) do
    [
      TESTING_DIR,
      File.join(TESTING_DIR, Gloss::Config.src_dir),
      File.join(TESTING_DIR, "sig"),
    ].each { |d| Dir.mkdir d unless Pathname(d).exist? }
  end

  config.after(:suite) do
    FileUtils.rm_r TESTING_DIR
  end
  config.include SpecHelpers
end

trap 'USR1' do
  puts "rspec pid: #{Process.pid}"
  threads = Thread.list

  puts
  puts "=" * 80
  puts "Received USR1 signal; printing all #{threads.count} thread backtraces."

  threads.each do |thr|
    description = thr == Thread.main ? "Main thread" : thr.inspect
    puts
    puts "#{description} backtrace: "
    puts thr.backtrace.join("\n")
  end

  puts "=" * 80
end
