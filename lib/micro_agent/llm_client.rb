require "langchain"
require "anthropic"

module MicroAgent
  class LLMClient
    MAX_RETRIES = 3
    RETRY_DELAY = 2 # seconds

    def initialize(provider_config)
      @provider = provider_config["provider"]
      @model = provider_config["model"]
      setup_client
    end

    def complete(prompt_or_messages)
      retries = 0
      begin
        case @provider
        when "anthropic"
          if prompt_or_messages.is_a?(Hash) || prompt_or_messages.is_a?(Array)
            # Convert messages to a single string for Anthropic
            prompt = prompt_or_messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")
            with_retries { @client.complete(prompt: prompt) }
          else
            with_retries { @client.complete(prompt: prompt_or_messages) }
          end
        when "open_ai"
          if prompt_or_messages.is_a?(Hash) || prompt_or_messages.is_a?(Array)
            with_retries { @client.chat(messages: prompt_or_messages) }
          else
            with_retries { @client.complete(prompt: prompt_or_messages) }
          end
        else
          raise "Unsupported provider: #{@provider}"
        end
      rescue => e
        puts "\nError: #{e.message}"
        if retries < MAX_RETRIES
          retries += 1
          puts "Retrying (#{retries}/#{MAX_RETRIES})..."
          sleep(RETRY_DELAY * retries)
          retry
        else
          raise
        end
      end
    end

    private

    def with_retries
      retries = 0
      begin
        yield
      rescue => e
        if retries < MAX_RETRIES
          retries += 1
          puts "\nError: #{e.message}"
          puts "Retrying (#{retries}/#{MAX_RETRIES})..."
          sleep(RETRY_DELAY * retries)
          retry
        else
          raise
        end
      end
    end

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
        default_options: {
          model: @model,
          max_retries: MAX_RETRIES,
          timeout: 30,
          max_tokens: 4096
        }
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
        default_options: {
          model: @model,
          max_retries: MAX_RETRIES,
          timeout: 30
        }
      )
    end
  end
end
