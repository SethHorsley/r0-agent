require "json"

module MicroAgent
  class Planner
    def initialize(config)
      @config = config
      @large_model = LLMClient.new(@config["large_provider"])
      @small_model = LLMClient.new(@config["small_provider"])
    end

    def create_initial_plan(task)
      prompt = <<~PROMPT
        As a software architect, create a detailed plan for the following task:
        #{task}

        Provide the response in the following JSON format:
        {
          "description": "Brief description of the solution",
          "files": [
            {
              "name": "filename.rb",
              "purpose": "What this file will do"
            }
          ],
          "steps": [
            "Step 1 description",
            "Step 2 description"
          ]
        }
      PROMPT

      response = @large_model.complete(prompt)
      JSON.parse(response)
    rescue JSON::ParserError
      puts "Error: Could not parse LLM response as JSON"
      nil
    end

    def create_test_file(plan, filename)
      prompt = <<~PROMPT
        Create a comprehensive test file using Minitest for the following plan:
        #{plan.to_json}

        Focus on the file: #{filename}
        Include edge cases and multiple test scenarios.
        Use proper Minitest syntax and best practices.
      PROMPT

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
      PROMPT

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
      PROMPT

      @small_model.complete(prompt)
    end
  end
end
