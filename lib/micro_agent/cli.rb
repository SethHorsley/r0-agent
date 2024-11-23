require "readline"

module MicroAgent
  class CLI
    def self.start
      new.start
    end

    def initialize
      @running = true
      setup_signal_handlers
      @config = MicroAgent.config
      validate_config
    end

    def start
      puts "Welcome to MicroAgent! Type 'exit' to quit or 'help' for commands."
      puts "Using #{@config["large_provider"]["provider"]} (#{@config["large_provider"]["model"]}) for large tasks"
      puts "Using #{@config["small_provider"]["provider"]} (#{@config["small_provider"]["model"]}) for small tasks"

      while @running
        begin
          input = Readline.readline("micro-agent> ", true)
          handle_input(input)
        rescue Interrupt
          puts "\nTo exit, type 'exit' or press Ctrl+C again"
        rescue => e
          puts "\nError: #{e.message}"
        end
      end
    end

    private

    def validate_config
      provider = @config["large_provider"]["provider"]
      if @config["providers"][provider].nil? || @config["providers"][provider]["api_key"].empty?
        puts "Warning: API key not configured for #{provider}"
        puts "Please edit ~/.config/micro-agent.yml to add your API key"
      end
    end

    def setup_signal_handlers
      # Handle Ctrl+C (SIGINT)
      Signal.trap("INT") do
        puts "\nGoodbye! Thanks for using MicroAgent."
        exit(0)
      end
    end

    def handle_input(input)
      return if input.nil?

      case input.strip.downcase
      when "exit", "quit"
        @running = false
        puts "Goodbye! Thanks for using MicroAgent."
      when "help"
        show_help
      when "config"
        reconfigure
      else
        process_command(input)
      end
    end

    def show_help
      puts <<~HELP
        Available commands:
        - help : Show this help message
        - exit : Exit the application
        - config : Reconfigure settings
        - create file <filename> : Create a new file
        - chat : Chat with the LLM
        
        Press Ctrl+C to exit at any time
      HELP
    end

    def reconfigure
      @config = Configuration.load_or_create
      validate_config
      puts "Configuration updated!"
    end
  end
end
