require_relative "micro_agent/version"
require_relative "micro_agent/configuration"
require_relative "micro_agent/planner"  # Add this line
require_relative "micro_agent/llm_client"  # Add this line if not already there
require_relative "micro_agent/cli"

module MicroAgent
  class Error < StandardError; end

  def self.config
    @config ||= Configuration.load_or_create
  end
end
