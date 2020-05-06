require "bundler/gem_tasks"

desc "compile the Crystal native extensions"
task :compile do
  puts "compiling native extensions"
  `cd ext/crystal_gem_template && shards && make clean && make & cd ../../`
end

desc "cleaning up compiled binaries"
task :clean do
  puts "cleaning up extensions"
  `cd ext/crystal_gem_template && make clean && cd ../../`
end
