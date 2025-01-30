module MicroAgent
  module CLI
    class CommandHandler
      COMMANDS = {
        "/help" => "Show this help message",
        "/exit" => "Exit the application",
        "/config" => "Reconfigure settings",
        "/create" => "Start a new creation workflow",
        "help" => "Show this help message"
      }.freeze

      def initialize(cli)
        @cli = cli
        setup_assistant
      end

      def handle_input(input)
        return if input.nil?

        command = input.strip.downcase

        case command
        when "/exit", "/quit"
          @cli.stop
        when "/help", "help"
          Display.show_help
        when "/config"
          reconfigure
        when "/create"
          @creation_workflow.start
        else
          handle_llm_prompt(input)
        end
      end

      private

      def setup_assistant
        config = MicroAgent.config
        provider = config["large_provider"]["provider"]
        model = config["large_provider"]["model"]
        api_key = config["providers"][provider]["api_key"]

        llm = case provider
        when "anthropic"
          Langchain::LLM::Anthropic.new(
            api_key: api_key,
            default_options: {
              model: model,
              temperature: 0.7
            }
          )
        when "open_ai"
          Langchain::LLM::OpenAI.new(
            api_key: api_key,
            default_options: {
              model: model,
              temperature: 0.7
            }
          )
        else
          raise "Unsupported provider: #{provider}"
        end

        @assistant = Langchain::Assistant.new(
          llm: llm,
          instructions: "You are a helpful AI assistant. Today is #{Time.now.strftime("%a %b %d %Y")}, local time is #{Time.now.strftime("%H %p")}."
        ) do |response_chunk|
          print response_chunk
          $stdout.flush
        end
      end

      def handle_llm_prompt(prompt)
        @assistant.add_message_and_run!(content: prompt)
        puts "\n" # Add newline after response
      rescue => e
        puts "\nError getting response: #{e.message}"
        puts e.backtrace if ENV["DEBUG"]
      end

      def reconfigure
        @config = Configuration.load_or_create
        validate_config
        setup_assistant
        puts "Configuration updated!"
      end
    end
  end
end
