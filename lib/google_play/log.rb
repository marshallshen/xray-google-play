require 'logger'

module GooglePlay
  module Log
    @loggers = {}

    def logger
      @logger ||= Log.logger_for(self.class.name)
    end

    def self.logger_for(klass)
      @loggers[klass] ||= configure_logger_for(klass)
    end

    def self.configure_logger_for(klass)
      logger = Logger.new(STDOUT)
      logger.progname = klass
      logger
    end
  end
end
