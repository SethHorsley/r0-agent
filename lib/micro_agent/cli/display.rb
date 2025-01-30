# File: ./lib/micro_agent/cli/display.rb
module MicroAgent
  module CLI
    class Display
      class << self
        def welcome_message(config)
          puts "Welcome to MicroAgent! Type 'exit' to quit or 'help' for commands."
          # puts "Using #{config["large_provider"]["provider"]} (#{config["large_provider"]["model"]}) for large tasks"
          # puts "Using #{config["small_provider"]["provider"]} (#{config["small_provider"]["model"]}) for small tasks"
        end

        def goodbye_message
          puts "Goodbye! Thanks for using MicroAgent."
        end

        def show_help
          puts <<~HELP
            Available commands:
            - help : Show this help message
            - exit : Exit the application
            - config : Reconfigure settings
            - create : Start a new creation workflow
            
            During creation:
            - You can describe your task
            - Review and edit the generated plan
            - Tests will be created and run automatically
            
            Press Ctrl+C to exit at any time
          HELP
        end

        def show_plan(plan)
          puts "\nPlan:"
          puts "Description: #{plan["description"]}"
          puts "\nFiles to create:"
          plan["files"].each do |file|
            puts "- #{file["name"]}: #{file["purpose"]}"
          end
        end

        def show_plan_options
          puts "\nWhat would you like to do?"
          puts "1. Execute the plan"
          puts "2. Edit the plan"
          puts "3. Start over"
          puts "4. Cancel"
          print "> "
        end

        def show_configuration_help
          puts "\nConfiguration Help:"
          puts "1. Anthropic API key: Get it from https://console.anthropic.com/account/keys"
          puts "2. OpenAI API key: Get it from https://platform.openai.com/api-keys"
          puts "\nUse the 'config' command to set up your API keys."
        end

        def show_api_error(provider)
          puts "\nError: #{provider} API key is not configured correctly."
          puts "Please make sure you have:"
          puts "1. Created an account with #{provider}"
          puts "2. Generated an API key"
          puts "3. Configured the key using the 'config' command"
          show_configuration_help
        end
      end
    end
  end
end
