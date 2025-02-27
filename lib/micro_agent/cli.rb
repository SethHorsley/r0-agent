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
        setup_line_editor
      end

      def start(options = {})
        if options[:create]
          CreationWorkflow.new.start
          return
        end

        Display.welcome_message(@config)

        while @running
          begin
            input = Reline.readline(Display.prompt_text, true)

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
            puts "\n\e[31mError:\e[0m #{e.message}"
            puts e.backtrace if ENV["DEBUG"]
          end
        end
      end

      def setup_line_editor
        Reline.completion_proc = proc { |word|
          # Add command completion for / commands
          CommandHandler::COMMANDS.keys.grep(/^#{Regexp.escape(word)}/)
        }

        # Set up persistent history
        history_file = File.expand_path("~/.micro_agent_history")
        if File.exist?(history_file)
          File.readlines(history_file).each do |line|
            Reline::HISTORY << line.chomp
          end
        end

        # Save history on exit
        at_exit do
          File.open(history_file, "w") do |f|
            Reline::HISTORY.each do |line|
              f.puts line
            end
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
