require "yaml"
require "fileutils"

module MicroAgent
  class Configuration
    CONFIG_PATH = File.expand_path("~/.config/micro-agent.yml")
    PROVIDERS = ["anthropic", "open_ai"]

    DEFAULT_CONFIG = {
      "providers" => {
        "anthropic" => {"api_key" => ""},
        "open_ai" => {"api_key" => ""}
      },
      "large_provider" => {
        "provider" => "open_ai",
        "model" => "gpt-4"
      },
      "small_provider" => {
        "provider" => "open_ai",
        "model" => "gpt-3.5-turbo"
      },
      "generation_strategy" => {
        "mode" => "single",  # can be "single" or "test_driven"
        "generate_tests" => false  # whether to generate tests in single mode
      }
    }

    def self.load_or_create
      new.load_or_create
    end

    def load_or_create
      if File.exist?(CONFIG_PATH)
        config = load_config
        # Merge with default config to ensure all keys exist
        DEFAULT_CONFIG.merge(config)
      else
        setup_config
      end
    end

    def reconfigure
      config = setup_config
      MicroAgent.instance_variable_set(:@config, config)
      config
    end

    private

    def load_config
      YAML.load_file(CONFIG_PATH) || DEFAULT_CONFIG
    rescue => e
      puts "Error loading config: #{e.message}"
      setup_config
    end

    def setup_config
      puts "Welcome to MicroAgent Setup!"
      puts "Let's configure your providers and models."
      puts "-----------------------------------"

      config = {
        "providers" => setup_providers,
        "large_provider" => setup_large_provider,
        "small_provider" => setup_small_provider,
        "generation_strategy" => setup_generation_strategy
      }

      save_config(config)
      config
    end

    def setup_providers
      providers = {}

      PROVIDERS.each do |provider|
        puts "\nSetup for #{provider}:"
        puts "Please enter your #{provider} API key"
        puts "(Get your key from: #{get_provider_url(provider)})"
        print "> "
        api_key = gets.chomp.strip
        providers[provider] = {"api_key" => api_key}
      end

      providers
    end

    def get_provider_url(provider)
      case provider
      when "anthropic"
        "https://console.anthropic.com/account/keys"
      when "open_ai"
        "https://platform.openai.com/api-keys"
      else
        "provider website"
      end
    end

    def setup_large_provider
      puts "\nLarge Language Model Configuration:"
      {
        "provider" => select_provider("large"),
        "model" => input_model("large")
      }
    end

    def setup_small_provider
      puts "\nSmall Language Model Configuration:"
      {
        "provider" => select_provider("small"),
        "model" => input_model("small")
      }
    end

    def select_provider(type)
      loop do
        puts "\nAvailable providers: #{PROVIDERS.join(", ")}"
        print "Select provider for #{type} model: "
        provider = gets.chomp.downcase
        return provider if PROVIDERS.include?(provider)
        puts "Invalid provider. Please select from the available options."
      end
    end

    def input_model(type)
      print "Enter model name for #{type} provider: "
      gets.chomp.strip
    end

    def save_config(config)
      FileUtils.mkdir_p(File.dirname(CONFIG_PATH))
      File.write(CONFIG_PATH, config.to_yaml)
      puts "\nConfiguration saved to #{CONFIG_PATH}"
    end

    def setup_generation_strategy
      puts "\nCode Generation Strategy Configuration:"
      puts "1. Single model (faster, no tests by default)"
      puts "2. Test-driven (uses two models, generates tests first)"
      print "Select strategy (1/2): "

      case gets.chomp.strip
      when "1"
        puts "\nGenerate tests in single model mode? (y/n)"
        generate_tests = gets.chomp.downcase.start_with?("y")
        {
          "mode" => "single",
          "generate_tests" => generate_tests
        }
      when "2"
        {
          "mode" => "test_driven",
          "generate_tests" => true
        }
      else
        puts "Invalid choice. Defaulting to single model mode without tests."
        {
          "mode" => "single",
          "generate_tests" => false
        }
      end
    end
  end
end
