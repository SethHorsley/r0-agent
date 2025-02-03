module MicroAgent
  module CLI
    class CommandHandler
      COMMANDS = {
        "/help" => "Show this help message",
        "/exit" => "Exit the application",
        "/config" => "Reconfigure settings",
        "/create" => "Start a new creation workflow",
        "/chat" => "Toggle chat mode (remembers conversation)",
        "/clear" => "Clear chat history",
        "help" => "Show this help message"
      }.freeze

      def initialize(cli)
        @cli = cli
        @chat_mode = true  # Default to chat mode
        setup_llm
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
        when "/chat"
          toggle_chat_mode
        when "/clear"
          clear_chat_history
        else
          handle_llm_prompt(input)
        end
      end

      private

      def setup_llm
        config = MicroAgent.config
        provider = config["large_provider"]["provider"]
        model = config["large_provider"]["model"]
        api_key = config["providers"][provider]["api_key"]

        @llm = case provider
        when "anthropic"
          Langchain::LLM::Anthropic.new(
            api_key: api_key,
            default_options: {
              model: model,
              temperature: 0.7,
              max_tokens: 1024
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

        setup_chat_history
      end

      def setup_chat_history
        @messages = []
        system_message = "You are a helpful AI assistant. Today is #{Time.now.strftime("%a %b %d %Y")}, local time is #{Time.now.strftime("%H %p")}."

        @messages << if @llm.is_a?(Langchain::LLM::Anthropic)
          {role: "assistant", content: system_message}
        else
          {role: "system", content: system_message}
        end
      end

      def handle_llm_prompt(prompt)
        if @chat_mode
          handle_chat_prompt(prompt)
        else
          handle_completion_prompt(prompt)
        end
      rescue => e
        puts "\nError getting response: #{e.message}"
        puts e.backtrace if ENV["DEBUG"]
      end

      def handle_chat_prompt(prompt)
        @messages << {role: "user", content: prompt}

        puts "\nThinking..."
        begin
          response = if @llm.is_a?(Langchain::LLM::Anthropic)
            @llm.chat(
              messages: @messages,
              stream: true
            ) do |chunk|
              # Parse and handle the streaming response
              if chunk.is_a?(String)
                print chunk
              elsif chunk.is_a?(Hash)
                case chunk["type"]
                when "content_block_delta"
                  if chunk.dig("delta", "text")
                    print chunk["delta"]["text"]
                  end
                when "message_delta", "message_start", "message_stop",
                     "content_block_start", "content_block_stop", "ping"
                  # Ignore these control messages
                else
                  # For debugging unknown message types
                  puts "\nUnknown chunk type: #{chunk["type"]}" if ENV["DEBUG"]
                end
              end
              $stdout.flush
            end
          else
            @llm.chat(messages: @messages) do |chunk|
              print chunk
              $stdout.flush
            end
          end

          @messages << {
            role: "assistant",
            content: response.chat_completion
          }
          puts "\n"
        rescue => e
          puts "\n\e[31mError:\e[0m #{e.message}"
          puts "Response: #{response.inspect}" if ENV["DEBUG"]
          puts e.backtrace if ENV["DEBUG"]
        end
      end

      def handle_completion_prompt(prompt)
        puts "\nThinking..."
        begin
          if @llm.is_a?(Langchain::LLM::Anthropic)
            @llm.complete(
              prompt: prompt,
              stream: true
            ) do |chunk|
              print chunk
              $stdout.flush
            end
          else
            @llm.complete(prompt: prompt) do |chunk|
              print chunk
              $stdout.flush
            end
          end
          puts "\n"
        rescue => e
          puts "\n\e[31mError:\e[0m #{e.message}"
          puts e.backtrace if ENV["DEBUG"]
        end
      end

      def toggle_chat_mode
        @chat_mode = !@chat_mode
        mode = @chat_mode ? "chat" : "completion"
        puts "\nSwitched to #{mode} mode"
        setup_chat_history if @chat_mode
      end

      def clear_chat_history
        setup_chat_history
        puts "\nChat history cleared"
      end

      def reconfigure
        @config = Configuration.load_or_create
        validate_config
        setup_llm
        puts "Configuration updated!"
      end
    end
  end
end
