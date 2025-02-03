require "langchain"

module MicroAgent
  class LLMClient
    def initialize(provider_config)
      @provider = provider_config["provider"]
      @model = provider_config["model"]
      setup_client
    end

    def complete(prompt, &block)
      case @provider
      when "anthropic"
        @client.complete(prompt: prompt, &block)
      when "open_ai"
        @client.complete(prompt: prompt, &block)
      else
        raise "Unsupported provider: #{@provider}"
      end
    end

    private

    def setup_client
      case @provider
      when "anthropic"
        setup_anthropic_client
      when "open_ai"
        setup_openai_client
      else
        raise "Unsupported provider: #{@provider}"
      end
    end

    def setup_anthropic_client
      api_key = MicroAgent.config.dig("providers", "anthropic", "api_key")
      if api_key.to_s.empty?
        puts "Anthropic API key not configured. Please run 'config' command to set it up."
        exit(1)
      end
      @client = Langchain::LLM::Anthropic.new(
        api_key: api_key,
        default_options: {model: @model}
      )
    end

    def setup_openai_client
      api_key = MicroAgent.config.dig("providers", "open_ai", "api_key")
      if api_key.to_s.empty?
        puts "OpenAI API key not configured. Please run 'config' command to set it up."
        exit(1)
      end
      @client = Langchain::LLM::OpenAI.new(
        api_key: api_key,
        default_options: {model: @model}
      )
    end
  end
end

# lib/micro_agent/cli/command_handler.rb
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
        @creation_workflow = CreationWorkflow.new
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
        llm = MicroAgent::LLMClient.new(MicroAgent.config["large_provider"])
        @assistant = Langchain::Assistant.new(
          llm: llm,
          instructions: "You are a helpful AI assistant."
        ) do |response_chunk|
          binding.pry
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

# Add to Gemfile:
# gem "langchainrb"
