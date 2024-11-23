require "yaml"
require "fileutils"

module MicroAgent
  class Configuration
    CONFIG_PATH = File.expand_path("~/.config/micro-agent.yml")
    PROVIDERS = ["anthropic", "open_ai"]

    def self.load_or_create
      new.load_or_create
    end

    def load_or_create
      if File.exist?(CONFIG_PATH)
        load_config
      else
        setup_config
      end
    end

    private

    def load_config
      YAML.load_file(CONFIG_PATH)
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
        "small_provider" => setup_small_provider
      }

      save_config(config)
      config
    end

    def setup_providers
      providers = {}

      PROVIDERS.each do |provider|
        puts "\nSetup for #{provider}:"
        print "Enter your #{provider} API key (press Enter to skip): "
        api_key = gets.chomp.strip
        providers[provider] = {"api_key" => api_key} unless api_key.empty?
      end

      providers
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
      # Create ~/.config directory if it doesn't exist
      FileUtils.mkdir_p(File.dirname(CONFIG_PATH))

      File.write(CONFIG_PATH, config.to_yaml)
      puts "\nConfiguration saved to #{CONFIG_PATH}"
    end
  end
end
