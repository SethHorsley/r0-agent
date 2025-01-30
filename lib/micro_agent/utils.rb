module MicroAgent
  class Utils
    def remove_initial_slash(path)
      path.start_with?("/") ? path[1..] : path
    end

    def remove_backticks(input)
      input
        .gsub(/[\s\S]*```(\w+)?\n([\s\S]*?)\n```[\s\S]*/m, '\2')
        .strip
    end
  end
end
