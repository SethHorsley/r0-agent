require_relative "micro_agent/version"
require_relative "micro_agent/configuration"
require_relative "micro_agent/cli"

module MicroAgent
  class Error < StandardError; end

  def self.config
    @config ||= Configuration.load_or_create
  end
end
