require "tempfile"
require "open3"

module MicroAgent
  module CLI
    class TestRunner
      MAX_RETRIES = 3

      def run_tests(test_file, implementation, planner)
        retries = 0

        loop do
          puts "\nRunning tests..."
          output, status = run_minitest(test_file)

          if status.success?
            puts "\n✅ All tests passed!"
            break
          else
            puts "\n❌ Tests failed:"
            puts output

            if retries >= MAX_RETRIES
              puts "\nMax retries reached. Please review the implementation manually."
              break
            end

            puts "\nAttempting to fix implementation (Attempt #{retries + 1}/#{MAX_RETRIES})..."
            implementation = planner.revise_implementation(
              File.read(test_file),
              implementation,
              output
            )

            # Update the implementation file
            File.write(File.dirname(test_file) + "/../" + File.basename(test_file, "_test.rb") + ".rb", implementation)

            retries += 1
          end
        end
      end

      private

      def run_minitest(test_file)
        output, status = Open3.capture2e("ruby", test_file)
        [output, status]
      end
    end
  end
end
