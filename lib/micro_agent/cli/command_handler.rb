module MicroAgent
  module CLI
    class CommandHandler
      def initialize(cli)
        @cli = cli
        @creation_workflow = CreationWorkflow.new
      end

      def handle_input(input)
        return if input.nil?

        case input.strip.downcase
        when "exit", "quit"
          @cli.stop
        when "help"
          Display.show_help
        when "config"
          reconfigure
        else
          process_command(input)
        end
      end

      private

      def process_command(input)
        case input.strip.downcase
        when /^create/
          @creation_workflow.start
        else
          puts "Unknown command. Type 'help' for available commands."
        end
      end

      def reconfigure
        @config = Configuration.load_or_create
        validate_config
        puts "Configuration updated!"
      end
    end
  end
end
