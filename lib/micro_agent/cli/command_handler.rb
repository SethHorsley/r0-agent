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
        "/analyze" => "Analyze codebase for a specific task",
        "help" => "Show this help message"
      }.freeze

      def initialize(cli)
        @cli = cli
        @chat_mode = true  # Default to chat mode
        setup_llm
      end

      def handle_input(input)
        return if input.nil?

        command = input.strip

        case command.downcase
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
        when "/analyze"
          handle_analysis_workflow
        else
          if @chat_mode
            handle_chat_prompt(input)
          else
            analyze_and_process(input)
          end
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

      def analyze_and_process(prompt)
        puts "\nAnalyzing codebase for relevant files..."
        relevant_files = MicroAgent::Utils.find_relevant_files(Dir.pwd, prompt)

        if relevant_files.empty?
          puts "No relevant files found for the given prompt."
          return
        end

        puts "\nFound relevant files:"
        relevant_files.each { |f| puts "- #{f}" }

        puts "\nAnalyzing files and generating response..."

        # Get file contents
        files_with_contents = relevant_files.map do |file|
          content = File.read(file)
          <<~FILE
            <file path="#{file}">
            #{content}
            </file>
          FILE
        end.join("\n\n")

        system_prompt = "You are an AI assistant analyzing code files. Use the provided file contents as context to answer questions or suggest changes."

        user_prompt = <<~PROMPT
          Here are the relevant files and their contents:

          #{files_with_contents}

          Task/Question: #{prompt}

          If suggesting changes, wrap the modified file content in XML tags like this:
          <file path="/path/to/file">
          [modified content]
          </file>
        PROMPT

        begin
          # Use streaming for the analysis response
          if @llm.is_a?(Langchain::LLM::Anthropic)
            @llm.chat(
              system: system_prompt,  # System message as a parameter
              messages: [
                {role: "user", content: user_prompt}
              ],
              stream: true,
              max_tokens: 4000
            ) do |chunk|
              if chunk.is_a?(String)
                print chunk
              elsif chunk.is_a?(Hash) && chunk.dig("delta", "text")
                print chunk["delta"]["text"]
              end
              $stdout.flush
            end
          else
            @llm.chat(
              messages: [
                {role: "system", content: system_prompt},
                {role: "user", content: user_prompt}
              ]
            ) do |chunk|
              print chunk
              $stdout.flush
            end
          end
          puts "\n"
        rescue => e
          puts "\n\e[31mError:\e[0m #{e.message}"
          if e.respond_to?(:response) && e.response
            puts "\nResponse details:"
            puts "Status: #{e.response.status}"
            puts "Body: #{e.response.body}"
          elsif e.respond_to?(:error)
            puts "\nError details:"
            puts e.error.inspect
          end
          puts "\nDebug information:" if ENV["DEBUG"]
          puts "System prompt length: #{system_prompt.length}" if ENV["DEBUG"]
          puts "User prompt length: #{user_prompt.length}" if ENV["DEBUG"]
          puts e.backtrace if ENV["DEBUG"]
          nil
        end
      end

      def handle_analysis_workflow
        puts "\nWhat would you like to analyze or modify in the codebase?"
        prompt = Reline.readline("analyze> ", true) # true enables history for this prompt
        return if prompt.nil? || prompt.strip.empty?
        analyze_and_process(prompt)
      end

      def apply_changes(response)
        changes = parse_changes(response)
        changes.each do |file_path, content|
          if File.exist?(file_path)
            puts "\nModifying existing file: #{file_path}"
            show_diff(file_path, content)
            print "Apply these changes? (y/n): "
            next unless gets.chomp.downcase == "y"
          else
            puts "\nCreating new file: #{file_path}"
            print "Create this file? (y/n): "
            next unless gets.chomp.downcase == "y"
            FileUtils.mkdir_p(File.dirname(file_path))
          end

          File.write(file_path, content)
          puts "Changes applied to #{file_path}"
        end
      end

      def parse_changes(response)
        changes = {}
        current_file = nil
        current_content = []

        response.split("\n").each do |line|
          if line.match?(/<file path="([^"]+)">/)
            if current_file
              changes[current_file] = current_content.join("\n")
              current_content = []
            end
            current_file = line.match(/<file path="([^"]+)">/)[1]
          elsif line.match?(/<\/file>/)
            if current_file
              changes[current_file] = current_content.join("\n")
              current_file = nil
              current_content = []
            end
          elsif current_file
            current_content << line
          end
        end

        changes
      end

      def show_diff(file_path, new_content)
        require "diffy"
        current_content = File.read(file_path)
        diff = Diffy::Diff.new(current_content, new_content)
        puts diff.to_s(:color)
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
