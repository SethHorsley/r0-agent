require_relative "micro_agent/version"
require_relative "micro_agent/configuration"
require_relative "micro_agent/llm_client"
require_relative "micro_agent/planner"
require_relative "micro_agent/cli"
require_relative "micro_agent/utils"
require_relative "micro_agent/railtie" if defined?(Rails)

module MicroAgent
  class Error < StandardError; end

  def self.config
    @config ||= Configuration.load_or_create
  end
end

class String
  # DedentOptions class for configuration
  class DedentOptions
    attr_accessor :escape_special_characters

    def initialize(options = {})
      @escape_special_characters = options[:escape_special_characters]
    end
  end

  # Class method to configure global dedent options
  def self.dedent_options=(options)
    @dedent_options = DedentOptions.new(options)
  end

  def self.dedent_options
    @dedent_options ||= DedentOptions.new
  end

  # Instance method for dedenting
  def dedent
    mindent = nil
    lines = split("\n")

    # Find minimum indentation
    lines.each do |line|
      if (m = line.match(/^(\s+)\S+/))
        indent = m[1].length
        mindent = mindent.nil? ? indent : [mindent, indent].min
      end
    end

    # Apply dedentation
    result = if mindent
      lines.map do |line|
        if line.start_with?(" ", "\t")
          line[mindent..]
        else
          line
        end
      end.join("\n")
    else
      lines.join("\n")
    end

    # Trim and handle escaped newlines
    result = result.strip
    if self.class.dedent_options.escape_special_characters
      result = result.gsub("\\n", "\n")
    end

    result
  end
end
