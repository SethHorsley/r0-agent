require "reline"
require_relative "planner"
require_relative "cli/command_handler"
require_relative "cli/creation_workflow"
require_relative "cli/plan_editor"
require_relative "cli/display"
require_relative "cli/test_runner"
require "langchain"
require "anthropic"  # Add this line

module MicroAgent
  module CLI
    class Runner
      def self.start(options = {})
        new.start(options)
      end

      def initialize
        @running = true
        @config = MicroAgent.config
        validate_config
        setup_components
      end

      def start(options = {})
        if options[:create]
          CreationWorkflow.new.start
          return
        end

        Display.welcome_message(@config)
        puts "Type your prompt or '/help' for available commands."
        puts "Press Ctrl+D to exit or Ctrl+C to clear current input."

        while @running
          begin
            input = Reline.readline("prompt> ", true)

            if input.nil?  # Handles Ctrl+D
              stop
              break
            end

            input = input.strip
            next if input.empty?
            @command_handler.handle_input(input)
          rescue Interrupt  # Handles Ctrl+C
            print "\r"  # Clear the current line
            next
          rescue => e
            puts "\nError: #{e.message}"
            puts e.backtrace if ENV["DEBUG"]
          end
        end
      end

      def stop
        @running = false
        puts  # Add newline for clean exit
        Display.goodbye_message
      end

      private

      def setup_components
        @command_handler = CommandHandler.new(self)
      end

      def validate_config
        provider = @config["large_provider"]["provider"]
        if @config["providers"][provider].nil? || @config["providers"][provider]["api_key"].empty?
          puts "Warning: API key not configured for #{provider}"
          puts "Please edit ~/.config/micro-agent.yml to add your API key"
        end
      end
    end

    def self.start(options = {})
      Runner.start(options)
    end
  end
end
