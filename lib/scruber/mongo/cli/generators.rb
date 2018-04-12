require "thor"
require 'fileutils'

module Scruber
  module CLI
    class Generators < Thor

      class MongoInstall < Thor::Group
        include Thor::Actions

        def self.source_root
          File.dirname(__FILE__) + '/templates'
        end

        def check_for_project
          raise ::Thor::Error, "ERROR: Scruber project not found." unless defined?(APP_PATH)
        end

        def create_files
          template 'mongo.tt', File.expand_path('../../config/mongo.yml', APP_PATH)
          template 'mongo_initializer.tt', File.expand_path('../../config/initializers/mongo.rb', APP_PATH)
        end

        def change_config
          gsub_file File.expand_path('../../config/application.rb', APP_PATH), /config\.fetcher_agent_adapter\s*=\s*\:(\w+)/, 'config.fetcher_agent_adapter = :mongo'
          gsub_file File.expand_path('../../config/application.rb', APP_PATH), /config.queue_adapter\s*=\s*\:(\w+)/, 'config.queue_adapter = :mongo'
        end
      end

      register MongoInstall, 'mongo:install', 'mongo:install', 'Install mongo'
    end
  end
end
