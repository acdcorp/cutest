require "./lib/cutest"

Gem::Specification.new do |s|
  s.name              = "cutest"
  s.version           = Cutest::VERSION
  s.summary           = "Forking tests."
  s.description       = "Run tests in separate processes to avoid shared state."
  s.authors           = ["Damian Janowski", "Michel Martens"]
  s.email             = ["djanowski@dimaion.com", "michel@soveran.com"]
  s.homepage          = "http://github.com/djanowski/cutest"

  s.files = Dir[
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "lib/**/*.rb",
    "*.gemspec",
    "test/**/*.*"
  ]

  s.executables.push "cutest"
end
