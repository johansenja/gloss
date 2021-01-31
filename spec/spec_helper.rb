require "gloss"
require "fileutils"

TESTING_DIR = "./tmp"

RSpec.configure do |config|
  config.before(:suite) do
    Dir.mkdir TESTING_DIR unless Pathname(TESTING_DIR).exist?
  end

  config.after(:suite) do
    FileUtils.rm_r TESTING_DIR
  end
end
