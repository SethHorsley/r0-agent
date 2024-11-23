module MicroAgent
  module CLI
    class CreationWorkflow
      def initialize
        check_configuration
        @planner = Planner.new(MicroAgent.config)
        @plan_editor = PlanEditor.new
        @test_runner = TestRunner.new
      end

      def start
        return unless check_configuration

        puts "\nWhat would you like to create? Describe your task:"
        task = gets.chomp

        puts "\nGenerating plan..."
        begin
          plan = @planner.create_initial_plan(task)
          return puts("\nError: Could not generate plan") unless plan

          Display.show_plan(plan)
          handle_plan_workflow(plan)
        rescue => e
          puts "\nError during plan generation: #{e.message}"
          puts e.backtrace if ENV["DEBUG"]
        end
      end

      private

      def check_configuration
        config = MicroAgent.config
        provider = config["large_provider"]["provider"]
        api_key = config.dig("providers", provider, "api_key")

        if api_key.to_s.empty?
          puts "\nAPI key not configured for #{provider}!"
          puts "Would you like to configure it now? (y/n)"
          if gets.chomp.downcase == "y"
            Configuration.new.reconfigure
            return check_configuration # Recheck after configuration
          else
            puts "Cannot proceed without API configuration."
            return false
          end
        end
        true
      end

      def handle_plan_workflow(plan)
        loop do
          Display.show_plan_options
          choice = gets.chomp

          case choice
          when "1"
            execute_plan(plan)
            break
          when "2"
            plan = @plan_editor.edit_plan(plan)
            Display.show_plan(plan) if plan
          when "3"
            start
            break
          when "4"
            puts "Operation cancelled"
            break
          else
            puts "Invalid choice"
          end
        end
      end

      def execute_plan(plan)
        plan["files"].each do |file|
          create_and_test_file(file, plan)
        end
      end

      def create_and_test_file(file, plan)
        puts "\nCreating tests for #{file["name"]}..."
        test_file = "test/#{File.basename(file["name"], ".*")}_test.rb"
        test_content = @planner.create_test_file(plan, file["name"])

        FileUtils.mkdir_p(File.dirname(test_file))
        File.write(test_file, test_content)
        puts "Created test file: #{test_file}"

        puts "\nCreating implementation..."
        implementation = @planner.create_implementation(test_content, plan, file["name"])

        FileUtils.mkdir_p(File.dirname(file["name"]))
        File.write(file["name"], implementation)
        puts "Created implementation: #{file["name"]}"

        @test_runner.run_tests(test_file, implementation, @planner)
      end
    end
  end
end
