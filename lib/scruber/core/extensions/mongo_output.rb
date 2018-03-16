module Scruber
  module Core
    module Extensions
      class MongoOutput < Base
        module CoreMethods

          def mongo_out(fields, options={})
            Scruber::Core::Extensions::MongoOutput.mongo_out self.scraper_name, Scruber::Core::Extensions::MongoOutput.default_suffix_name, fields, options
          end

          def mongo_find(id)
            Scruber::Core::Extensions::MongoOutput.mongo_find self.scraper_name, Scruber::Core::Extensions::MongoOutput.default_suffix_name, id
          end

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
          attr_writer :default_suffix_name

          def default_suffix_name
            @default_suffix_name ||= 'records'
          end

          def mongo_out(scraper_name, suffix, fields, options={})
            fields = fields.with_indifferent_access
            if fields[:_id].blank?
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].insert_one(fields)
            else
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find_one_and_update(
                {"_id" => fields[:_id] },
                {'$set' => fields },
                {return_document: :before, upsert: true}.merge(options)
              )
            end
          end

          def mongo_find(scraper_name, suffix, id)
            if id.is_a?(Hash)
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find(id)
            else
              Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find({_id: id}).first
            end
          end

          def mongo_collection(scraper_name, suffix)
            Scruber::Mongo.client[out_collection_name(scraper_name, suffix)]
          end

          def out_collection_name(scraper_name, suffix)
            [Scruber::Mongo.configuration.options['collections_prefix'], scraper_name, suffix].select(&:present?).map(&:to_s).join('_')
          end

        end

      end
    end
  end
end
