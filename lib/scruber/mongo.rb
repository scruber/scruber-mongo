require 'yaml'
require 'scruber'
require 'mongo'
require "scruber/mongo/version"
require "scruber/mongo/configuration"
require "scruber/mongo/factory"
require "scruber/mongo/cli/generators"

require "scruber/queue_adapters/mongo"
require "scruber/core/extensions/mongo_output"
require "scruber/helpers/fetcher_agent_adapters/mongo"

module Scruber
  module Mongo
    class << self
      attr_writer :configuration
      attr_writer :clients

      def configuration
        @configuration ||= ::Scruber::Mongo::Configuration.new
      end

      def configure(&block)
        yield configuration
      end

      def client(client_name=:default)
        @clients ||= {}
        @clients[client_name] ||= Scruber::Mongo::Factory.create_client(client_name)
      end

    end
  end
end
