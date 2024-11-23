# File: ./lib/micro_agent/cli.rb
require "readline"
require_relative "planner"  # Add this line
require_relative "cli/command_handler"
require_relative "cli/creation_workflow"
require_relative "cli/plan_editor"
require_relative "cli/display"
require_relative "cli/test_runner"

module MicroAgent
  module CLI
    class Runner
      def self.start
        new.start
      end

      def initialize
        @running = true
        setup_signal_handlers
        @config = MicroAgent.config
        validate_config
        setup_components
      end

      def start
        Display.welcome_message(@config)

        while @running
          begin
            input = Readline.readline("micro-agent> ", true)
            @command_handler.handle_input(input)
          rescue Interrupt
            puts "\nTo exit, type 'exit' or press Ctrl+C again"
          rescue => e
            puts "\nError: #{e.message}"
            puts e.backtrace if ENV["DEBUG"]
          end
        end
      end

      def stop
        @running = false
        Display.goodbye_message
      end

      private

      def setup_components
        @planner = MicroAgent::Planner.new(@config)
        @command_handler = CommandHandler.new(self)
      end

      def setup_signal_handlers
        Signal.trap("INT") do
          puts "\nGoodbye! Thanks for using MicroAgent."
          exit(0)
        end
      end

      def validate_config
        provider = @config["large_provider"]["provider"]
        if @config["providers"][provider].nil? || @config["providers"][provider]["api_key"].empty?
          puts "Warning: API key not configured for #{provider}"
          puts "Please edit ~/.config/micro-agent.yml to add your API key"
        end
      end
    end

    def self.start
      Runner.start
    end
  end
end
