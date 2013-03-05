$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_import/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_import"
  s.version     = ActiveImport::VERSION
  s.authors     = ["David Monagle"]
  s.email       = ["david.monagle@intrica.com.au"]
  s.homepage    = "http://www.intrica.com.au"
  s.summary     = "Assist with the import of CSV and Excel files into models."
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.0.0"
  s.add_dependency "colorize"
  s.add_dependency "roo", ">= 1.2.3"

  s.add_development_dependency "sqlite3"
end
