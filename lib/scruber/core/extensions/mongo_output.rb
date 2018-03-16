module Scruber
  module Core
    module Extensions
      class MongoOutput < Base
        module CoreMethods

          def mongo_out(fields, options={})
            Scruber::Core::Extensions::MongoOutput.mongo_out self.scraper_name, :records, fields, options
          end

          def mongo_find(id)
            Scruber::Core::Extensions::MongoOutput.mongo_find self.scraper_name, :records, id
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
          end
        end

        class << self

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
            query = id.is_a?(Hash) ? id : {_id: id}
            Scruber::Mongo.client[out_collection_name(scraper_name, suffix)].find(query).first
          end

          def out_collection_name(scraper_name, suffix)
            [Scruber::Mongo.configuration.options['collections_prefix'], scraper_name, suffix].select(&:present?).map(&:to_s).join('_')
          end

        end

      end
    end
  end
end
