require "./lib/gloss/version"

Gem::Specification.new do |s|
  s.name          = 'gloss'
  s.version       = Gloss::VERSION
  s.licenses      = %w[MIT]
  s.summary       = "A superset of ruby"
  s.description   =
    "A rich language which compiles to ruby. Including type annotations, type checking, macros, annotations, enums and more"
  s.authors       = %w[johansenja]
  s.extensions    = %w[ext/gloss/extconf.rb]
  s.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.add_runtime_dependency "fast_blank"
  s.add_runtime_dependency "listen"
  s.add_runtime_dependency "rbs"
  s.add_runtime_dependency "steep"

  s.add_development_dependency "rake-compiler"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "rubocop"
end
