# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "grape-academic-theme"
  spec.version       = "0.1.0"
  spec.authors       = ["chrjabs"]
  spec.email         = ["christoph.jabs@helsinki.fi"]

  spec.summary       = "A free and open-source Jekyll theme for academic portfolios."
  spec.homepage      = "https://chrjabs.github.io/Grape-Academic-Theme/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README)!i) }

  spec.add_runtime_dependency "jekyll"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
