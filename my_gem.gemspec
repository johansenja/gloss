require "./lib/crystal_gem_template/version"

Gem::Specification.new do |s|
  s.name          = 'crystal_gem_template'
  s.version       = CrystalGemTemplate::VERSION
  s.licenses      = %w[MIT]
  s.summary       = "My first gem, written in crystal"
  s.description   = "Features include: Greeting anyone of your choice"
  s.authors       = %w[johansenja]
  s.files         = Dir["./**/*"]
  s.extensions    = %w[ext/crystal_gem_template/extconf.rb]
end
