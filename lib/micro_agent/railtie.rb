module MicroAgent
  class Railtie < Rails::Railtie
    generators do
      require "generators/micro_agent/install/install_generator"
    end
  end
end
