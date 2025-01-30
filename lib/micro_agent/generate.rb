require_relative "llm"
require "fileutils"
require "colorize"  # For color output

class Generator
  SYSTEM_PROMPT = <<~PROMPT.dedent
    You take a prompt and existing unit tests and generate the function implementation accordingly.

    1. Think step by step about the algorithm, reasoning about the problem and the solution, similar algorithm, the state, data structures and strategy you will use. Explain all that without emitting any code in this step.

    2. Emit a markdown code block with production-ready generated code (function that satisfies all the tests and the prompt).
    - Be sure your code exports function that can be called by an external test file.
    - Make sure your code is reusable and not overly hardcoded to match the prompt.
    - Use two spaces for indents. Add logs if helpful for debugging, you will get the log output on your next try to help you debug.
    - Always return a complete code snippet that can execute, nothing partial and never say "rest of your code" or similar, I will copy and paste your code into my file without modification, so it cannot have gaps or parts where you say to put the "rest of the code" back in.
    - Do not emit tests, just the function implementation.

    Stop emitting after the code block`;"
  PROMPT

  def self.generate(options)
    new(options).generate
  end

  def initialize(options)
    @options = options
  end

  def generate
    prompt = read_file(@options.prompt_file)
    prior_code = read_file(@options.output_file)
    test_code = read_file(@options.test_file)
    package_json = read_file("package.json")

    user_prompt = <<~PROMPT.dedent
      Here is what I need:

      <prompt>
      #{prompt || "Pass the tests"}
      </prompt>

      The current code is:
      <code>
      #{prior_code || "None"}
      </code>

      The file path for the above is #{@options.output_file}.

      The test code that needs to pass is:
      <test>
      #{test_code}
      </test>

      The file path for the test is #{@options.test_file}.

      The error you received on that code was:
      <error>
      #{@options.last_run_error || "None"}
      </error>

      #{package_json_section(package_json)}

      Please update the code (or generate all new code if needed) to satisfy the prompt and test.

      Be sure to use good coding conventions. For instance, if you are generating a typescript
      file, use types (e.g. for function parameters, etc).

      #{interactive_section}
    PROMPT

    puts "\n\nPrompt:".blue + user_prompt + "\n\n" if ENV["MA_DEBUG"]

    LLMClient.get_completion(
      options: @options,
      messages: [
        {
          role: "system",
          content: SYSTEM_PROMPT  # Assuming this is defined elsewhere
        },
        {
          role: "user",
          content: user_prompt
        }
      ]
    )
  end

  private

  def read_file(path)
    File.read(path)
  rescue Errno::ENOENT
    ""
  end

  def package_json_section(package_json)
    return "" if package_json.empty?

    <<~SECTION.dedent
      Don't use any node modules that aren't included here unless specifically told otherwise:
      <package-json>
      #{package_json}
      </package-json>
    SECTION
  end

  def interactive_section
    return "" if @options.interactive

    <<~SECTION.dedent
      If there is already existing code, strictly maintain the same coding style as the existing code.
      Any updated code should look like its written by the same person/team that wrote the original code.
    SECTION
  end
end
