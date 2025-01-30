module MicroAgent
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_executable
        template "agent.tt", "bin/agent"
        chmod "bin/agent", 0o755
      end

      private

      def chmod(path, mode)
        File.chmod(mode, path)
      end
    end
  end
end
