require_relative "llm_client"

module MicroAgent
  class Utils
    def self.find_relevant_files(directory, query)
      config = MicroAgent.config
      llm = LLMClient.new(config["large_provider"])

      files = Dir.glob("#{directory}/**/*").reject { |f| File.directory?(f) }

      file_list = files.map do |f|
        relative_path = Pathname.new(f).relative_path_from(Pathname.new(directory)).to_s
        "- #{relative_path}"
      end.join("\n")

      system_prompt = "You are an assistant that helps identify relevant files for code changes. List only the most relevant files for the given task, ordered by relevance."

      user_prompt = <<~PROMPT
        Here is the current directory structure:

        #{file_list}

        Task: #{query}

        List only the file paths of the most relevant files, one per line.
        Do not include any other text or explanations.
      PROMPT

      begin
        response = llm.complete(system_prompt + "\n\n" + user_prompt)
        relevant_paths = response.completion.strip.split("\n")
        relevant_paths.map { |path| files.find { |f| f.end_with?(path.strip) } }.compact
      rescue => e
        puts "\nError finding relevant files: #{e.message}"
        puts "Try again in a few moments..."
        []
      end
    end

    def self.get_files_content_and_process(files, prompt)
      return if files.empty?

      config = MicroAgent.config
      llm = LLMClient.new(config["large_provider"])

      files_with_contents = files.map do |file|
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
        response = llm.complete(system_prompt + "\n\n" + user_prompt)
        response.completion
      rescue => e
        puts "\nError processing files: #{e.message}"
        puts "Try again in a few moments..."
        nil
      end
    end

    def remove_initial_slash(path)
      path.start_with?("/") ? path[1..] : path
    end

    def remove_backticks(input)
      input
        .gsub(/[\s\S]*```(\w+)?\n([\s\S]*?)\n```[\s\S]*/m, '\2')
        .strip
    end
  end
end
