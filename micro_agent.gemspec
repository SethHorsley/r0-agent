# frozen_string_literal: true

require_relative "lib/micro_agent/version"

Gem::Specification.new do |spec|
  spec.name = "micro-agent"
  spec.version = MicroAgent::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "A CLI chat interface for LLM interaction"
  spec.description = "Chat with an LLM and create files directly from the terminal"
  spec.homepage = "https://github.com/yourusername/micro-agent"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.glob("{lib,exe}/**/*") + %w[README.md LICENSE.txt]
  spec.bindir = "exe"
  spec.executables = ["micro-agent"]
  spec.require_paths = ["lib"]

  spec.add_dependency "readline"
  spec.add_dependency "openai"  # or whatever LLM client you want to use
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.files += Dir["lib/generators/**/*"]
end
