module Scruber
  module Mongo
    module Factory
      extend self

      def create_client(client_name=:default)
        raise Scruber::ArgumentError.new("Not configured") unless Scruber::Mongo.configuration.configured?(client_name)
        configuration = Scruber::Mongo.configuration.clients[client_name]
        if configuration[:uri]
          ::Mongo::Client.new(configuration[:uri], options(configuration))
        else
          ::Mongo::Client.new(
            configuration[:hosts],
            options(configuration).merge(database: configuration[:database])
          )
        end
      end

      def options(configuration)
        config = configuration.dup
        options = config.delete(:options) || {}
        options.reject{ |k, v| k == :hosts }.to_hash.symbolize_keys!
      end
    end
  end
end