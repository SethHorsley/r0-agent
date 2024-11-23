require "openai"
require "net/http"
require "uri"
require "json"

module MicroAgent
  class LLMClient
    ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

    def initialize(provider_config)
      @provider = provider_config["provider"]
      @model = provider_config["model"]
    end

    def complete(prompt)
      setup_client unless @client

      case @provider
      when "anthropic"
        anthropic_complete(prompt)
      when "open_ai"
        openai_complete(prompt)
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
      @api_key = MicroAgent.config.dig("providers", "anthropic", "api_key")
      if @api_key.to_s.empty?
        puts "Anthropic API key not configured. Please run 'config' command to set it up."
        exit(1)
      end
    end

    def setup_openai_client
      api_key = MicroAgent.config.dig("providers", "open_ai", "api_key")
      if api_key.to_s.empty?
        puts "OpenAI API key not configured. Please run 'config' command to set it up."
        exit(1)
      end

      @client = OpenAI::Client.new(access_token: api_key)
    end

    def anthropic_complete(prompt)
      uri = URI(ANTHROPIC_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-Api-Key"] = @api_key
      request["anthropic-version"] = "2023-06-01"

      request.body = {
        model: @model,
        max_tokens: 1024,
        messages: [
          {role: "user", content: prompt}
        ]
      }.to_json

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)["content"].first["text"]
      else
        error_message = begin
                          JSON.parse(response.body)["error"]["message"]
        rescue
                          response.message
        end
        puts "Anthropic API error: #{error_message}"
        puts "Status code: #{response.code}"
        puts "Response body: #{response.body}" if ENV["DEBUG"]
        exit(1)
      end
    rescue => e
      puts "Error making Anthropic API request: #{e.message}"
      puts e.backtrace if ENV["DEBUG"]
      exit(1)
    end

    def openai_complete(prompt)
      response = @client.chat(
        parameters: {
          model: @model,
          messages: [{role: "user", content: prompt}]
        }
      )
      response.dig("choices", 0, "message", "content")
    rescue => e
      puts "OpenAI API error: #{e.message}"
      exit(1)
    end
  end
end
