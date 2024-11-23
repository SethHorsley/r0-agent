require "tempfile"
require "json"

module MicroAgent
  module CLI
    class PlanEditor
      def edit_plan(plan)
        editor = ENV["EDITOR"] || "vim"
        temp_file = Tempfile.new(["plan", ".json"])

        begin
          temp_file.write(JSON.pretty_generate(plan))
          temp_file.close

          system("#{editor} #{temp_file.path}")

          edited_content = File.read(temp_file.path)
          JSON.parse(edited_content)
        rescue JSON::ParserError => e
          puts "Error: Invalid JSON format - #{e.message}"
          nil
        rescue => e
          puts "Error editing plan: #{e.message}"
          nil
        ensure
          temp_file.unlink
        end
      end
    end
  end
end
