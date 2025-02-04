module MicroAgent
  module CLI
    class Display
      class << self
        def welcome_message(config)
          puts "\e[32m# 🤖 MicroAgent CLI v#{MicroAgent::VERSION}\e[0m"
          puts "# Using \e[36m#{config["large_provider"]["provider"]}\e[0m (\e[36m#{config["large_provider"]["model"]}\e[0m) 🧠"
          puts "# Type \e[33m/help\e[0m for available commands 📚"
          puts "#"
          puts "# \e[90m💬 Chat mode enabled. History will be remembered.\e[0m"
          puts
        end

        def show_help
          puts "\n📋 Available commands:"
          CommandHandler::COMMANDS.each do |cmd, desc|
            puts "  \e[33m#{cmd.ljust(15)}\e[0m : #{desc}"
          end
          puts "\n💬 Chat Mode:"
          puts "  • When enabled (default), maintains conversation history"
          puts "  • Use \e[33m/chat\e[0m to toggle between chat and completion modes"
          puts "  • Use \e[33m/clear\e[0m to reset chat history"
          puts "\n⌨️  Shortcuts:"
          puts "  • \e[33mCtrl+D\e[0m : Exit the console"
          puts "  • \e[33mCtrl+C\e[0m : Clear current input"
          puts
        end

        def goodbye_message
          puts "\n\e[32m# 👋 Thank you for using MicroAgent!\e[0m"
        end

        def prompt_text
          "\e[36m🤖 micro-agent\e[0m> "  # Cyan prompt with robot emoji
        end
      end
    end
  end
end