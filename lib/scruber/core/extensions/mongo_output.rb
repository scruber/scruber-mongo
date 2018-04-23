module Scruber
  module Core
    module Extensions

      # 
      # Extension for writing results to mongo collections.
      # It registers methods for writing documents:
      #     mongo_out({..}) # writing document to {prefix}_{scraper_name}_records
      #     mongo_out_product({..}) # writing document to {prefix}_{scraper_name}_product
      # Searching methods:
      #     mongo_find({..}) # searching document in {prefix}_{scraper_name}_records
      #     mongo_find_product({..}) # searching document in {prefix}_{scraper_name}_product
      # Accessing to mongo collection:
      #     mongo_collection({..}) # Direct access to {prefix}_{scraper_name}_records
      #     mongo_product_collection({..}) # Direct access to {prefix}_{scraper_name}_product
      # 
      # @example Writing products data and companies
      #   Scruber.run :simple do
      #     get_product 'http://example.com/product'
      #     get_company 'http://example.com/product'
      # 
      #     parse_product :html do |page,doc|
      #       id = mongo_out_product {title: doc.at('h1').text, price: doc.at('.price').text }
      #       record = mongo_find_product id
      #       record[:description] = doc.at('.desc').text
      #       mongo_out_product record
      #       log "Count: #{mongo_product_collection.count}"
      #     end
      # 
      #     parse_company :html do |page,doc|
      #       mongo_out_company {name: doc.at('h1').text, phone: doc.at('.phone').text }
      #     end
      #   end
      # 
      # @author Ivan Goncharov
      # 
      class MongoOutput < Base
        module CoreMethods

          # 
          # Mongo out default method. By default it uses suffix *_records*
          # 
          # @param fields [Hash] Fields to output
          # @param options [Hash] Output options, see https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndUpdate/
          # 
          # @return [Object] id of writed record
          def mongo_out(fields, options={})
            Scruber::Core::Extensions::MongoOutput.mongo_out self.scraper_name, Scruber::Core::Extensions::MongoOutput.default_suffix_name, fields, options
          end

          # 
          # Find mongo document by id
          # 
          # @param id [Object] id of document
          # 
          # @return [Hash] mongo document
          def mongo_find(id)
            Scruber::Core::Extensions::MongoOutput.mongo_find self.scraper_name, Scruber::Core::Extensions::MongoOutput.default_suffix_name, id
          end

          # 
          # Direct access to mongo collection
          # 
          # @return [Mongo::Collection] Mongo collection instance
          def mongo_collection
            Scruber::Core::Extensions::MongoOutput.mongo_collection self.scraper_name, Scruber::Core::Extensions::MongoOutput.default_suffix_name
          end

          def self.included(base)
            Scruber::Core::Crawler.register_method_missing /\Amongo_out_(\w+)\Z/ do |meth, scan_results, args|
              suffix = scan_results.first.first.to_sym
              fields, options = args.first
              fields = {} if fields.nil?
              Scruber::Core::Crawler.class_eval do
                define_method "mongo_out_#{suffix}".to_sym do |fields, opts={}|
                  Scruber::Core::Extensions::MongoOutput.mongo_out(self.scraper_name, suffix, fields, opts)
                end
              end
              Scruber::Core::Extensions::MongoOutput.mongo_out(self.scraper_name, suffix, fields, options)
            end
            Scruber::Core::Crawler.register_method_missing /\Amongo_find_(\w+)\Z/ do |meth, scan_results, args|
              suffix = scan_results.first.first.to_sym
              id = args.first
              Scruber::Core::Crawler.class_eval do
                define_method "mongo_find_#{suffix}".to_sym do |id|
                  Scruber::Core::Extensions::MongoOutput.mongo_find(self.scraper_name, suffix, id)
                end
              end
              Scruber::Core::Extensions::MongoOutput.mongo_find(self.scraper_name, suffix, id)
            end
            Scruber::Core::Crawler.register_method_missing /\Amongo_(\w+)_collection\Z/ do |meth, scan_results, args|
              suffix = scan_results.first.first.to_sym
              Scruber::Core::Crawler.class_eval do
                define_method "mongo_#{suffix}_collection".to_sym do
                  Scruber::Core::Extensions::MongoOutput.mongo_collection(self.scraper_name, suffix)
                end
              end
              Scruber::Core::Extensions::MongoOutput.mongo_collection(self.scraper_name, suffix)
            end
          end
        end

        class << self
          # Default mongo collection suffix name
          attr_writer :default_suffix_name

          # 
          # Default mongo collection suffix name
          # 
          # @return [String] Default mongo collection suffix name
          def default_suffix_name
            @default_suffix_name ||= 'records'
          end

          # 
          # Writing results to mongo collection
          # 
          # @param scraper_name [String] name of scraper to build collection name
          # @param suffix [String] suffix to build collection name
          # @param fields [Hash] Document to output
          # @param options [Hash] Options for updating record (when *_id* not set), see https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndUpdate/
          # 
          # @return [type] [description]
          def mongo_out(scraper_name, suffix, fields, options={})
            fields = fields.with_indifferent_access
            if fields[:_id].blank?
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].insert_one(fields).inserted_id
            else
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find_one_and_update(
                {"_id" => fields[:_id] },
                {'$set' => fields },
                {return_document: :after, upsert: true}.merge(options)
              )[:_id]
            end
          end

          # 
          # Searching document in mongo
          # 
          # @param scraper_name [String] name of scraper to build collection name
          # @param suffix [String] suffix to build collection name
          # @param id [Object] id of document
          # 
          # @return [Hash] document
          def mongo_find(scraper_name, suffix, id)
            if id.is_a?(Hash)
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find(id)
            else
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find({_id: id}).first
            end
          end

          # 
          # Access to mongo collection
          # 
          # @param scraper_name [String] name of scraper to build collection name
          # @param suffix [String] suffix to build collection name
          # 
          # @return [Mongo::Collection] instance of Mongo::Collection
          def mongo_collection(scraper_name, suffix)
            Scruber::Mongo.client[out_collection_name(scraper_name, suffix)]
          end

          # 
          # Collection name builder
          # 
          # @param scraper_name [String] name of scraper to build collection name
          # @param suffix [String] suffix to build collection name
          # 
          # @return [String] name of collection for given scraper_name and suffix
          def out_collection_name(scraper_name, suffix)
            [Scruber::Mongo.configuration.options['collections_prefix'], scraper_name, suffix].select(&:present?).map(&:to_s).join('_')
          end

        end

      end
    end
  end
end
