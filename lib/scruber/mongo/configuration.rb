module Scruber
  module Mongo
    class Configuration
      attr_accessor :clients, :options

      def initialize
        @clients = {}
        @options = {}
      end

      def load!(path)
        config = YAML.load_file(path).with_indifferent_access
        @clients = config['clients']
        @options = config['options']
      end

      def configured?(client_name=:default)
        @clients.key?(client_name)
      end

    end
  end
end