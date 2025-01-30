require "json"

module MicroAgent
  class Planner
    def initialize(config)
      @config = config
      @generation_strategy = config["generation_strategy"]
      @large_model = LLMClient.new(@config["large_provider"])
      @small_model = LLMClient.new(@config["small_provider"])
    end

    def create_implementation(test_content, plan, filename)
      prompt = if @generation_strategy["mode"] == "test_driven"
        # Existing test-driven implementation
        <<~PROMPT
          Create a Ruby implementation that passes the following tests:
          #{test_content}

          Following this plan:
          #{plan.to_json}

          For the file: #{filename}
          Ensure the implementation follows Ruby best practices and passes all test cases.
          Return ONLY the Ruby code without any markdown or explanations.
        PROMPT
      else
        # Single model implementation without test requirements
        <<~PROMPT
          Create a Ruby implementation for the following plan:
          #{plan.to_json}

          For the file: #{filename}
          #{generate_test_prompt if @generation_strategy["generate_tests"]}
          Ensure the implementation follows Ruby best practices.
          Return ONLY the Ruby code without any markdown or explanations.
        PROMPT
      end

      model = (@generation_strategy["mode"] == "test_driven") ? @small_model : @large_model
      model.complete(prompt)
    end

    def create_test_file(plan, filename)
      prompt = <<~PROMPT
        Create a comprehensive test file using Minitest for the following plan:
        #{plan.to_json}

        Focus on the file: #{filename}
        Include edge cases and multiple test scenarios.
        Use proper Minitest syntax and best practices.
        Return ONLY the Ruby code without any markdown or explanations.
      PROMPT

      puts "---------------- test file prompt ----------------"
      puts prompt
      @large_model.complete(prompt)
    end

    def create_implementation(test_content, plan, filename)
      prompt = <<~PROMPT
        Create a Ruby implementation that passes the following tests:
        #{test_content}

        Following this plan:
        #{plan.to_json}

        For the file: #{filename}
        Ensure the implementation follows Ruby best practices and passes all test cases.
        Return ONLY the Ruby code without any markdown or explanations.
      PROMPT

      puts "---------------- implementation prompt ----------------"
      puts prompt
      @small_model.complete(prompt)
    end

    def revise_implementation(test_content, current_implementation, errors)
      prompt = <<~PROMPT
        The following implementation failed these tests:
        #{test_content}

        Current implementation:
        #{current_implementation}

        Errors:
        #{errors}

        Please provide a revised implementation that passes all tests.
        Return ONLY the Ruby code without any markdown or explanations.
      PROMPT

      puts "---------------- revise implementation prompt ----------------"
      puts prompt
      @small_model.complete(prompt)
    end

    def generate_test_prompt
      "Include tests in the same file using Minitest."
    end

    def get_response(prompt)
      # Use the large model for general prompts
      @large_model.complete(prompt)
    end
  end
end
