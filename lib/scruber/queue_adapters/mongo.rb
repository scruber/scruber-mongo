module Scruber
  module QueueAdapters
    class Mongo < AbstractAdapter

      class Page < Scruber::QueueAdapters::AbstractAdapter::Page
        def id
          @options[:_id] || @id
        end

        def save(options={}, save_options={})
          if id.blank?
            @queue.collection.insert_one(attrs)
          else
            if options[:new]
              @queue.collection.find_one_and_update(
                {"_id" => self.id },
                {'$setOnInsert' => attrs },
                {return_document: :after, upsert: true, projection: {_id: 1}}.merge(options)
              )
            else
              @queue.collection.find_one_and_update(
                {"_id" => self.id },
                {'$set' => attrs },
                {return_document: :after, upsert: true, projection: {_id: 1}}.merge(options)
              )
            end
          end
        end

        def attrs
          @options.with_indifferent_access.except('id', '_id').merge(id.present? ? {_id: id} : {}).merge (instance_variables.select{|ivar| !(ivar.to_s =~ /\@_/) }-[:@options, :@queue]).inject({}){|acc,ivar| acc[ivar[1..-1]] = instance_variable_get(ivar);acc }.with_indifferent_access
        end

        def delete
          @queue.collection.find({"_id" => self.id }).delete_one if self.id.present?
        end
      end

      # def initialize(options={})
      #   super(options)
      # end

      def add(url_or_page, options={})
        if url_or_page.is_a?(Page)
          url_or_page.queue = self
          url_or_page.save({new: true}.merge(options))
        else
          Page.new(self, options.merge(url: url_or_page)).save({new: true})
        end
      end
      alias_method :push, :add

      def size
        collection.count
      end

      def downloaded_count
        collection.find({fetched_at: {"$gt" => 0}}).count
      end

      def find(id)
        build_pages collection.find({_id: id}).first
      end

      def fetch_downloaded(count=nil)
        if count.nil?
          build_pages collection.find({fetched_at: {"$gt" => 0}, processed_at: 0}).first
        else
          build_pages collection.find({fetched_at: {"$gt" => 0}, processed_at: 0}).limit(count).to_a
        end
      end

      def fetch_pending(count=nil)
        if count.nil?
          build_pages collection.find({fetched_at: 0, retry_count: {"$lt" => ::Scruber.configuration.fetcher_options[:max_retry_times]}, retry_at: {"$lte" => Time.now.to_i}}).first
        else
          build_pages collection.find({fetched_at: 0, retry_count: {"$lt" => ::Scruber.configuration.fetcher_options[:max_retry_times]}, retry_at: {"$lte" => Time.now.to_i}}).limit(count).to_a
        end
      end

      def has_work?
        fetch_pending.present? || fetch_downloaded.present?
      end

      def collection
        Scruber::Mongo.client[pages_collection_name]
      end

      def initialized?
        Scruber::Mongo.client[pages_collection_name].find.first.present?
      end

      private

        def build_pages(pages)
          if pages.nil?
            nil
          elsif pages.is_a?(Array)
            pages.map{|p| Page.new(self, p.with_indifferent_access.merge(url: p['url']) )}
          else
            Page.new(self, pages.with_indifferent_access.merge(url: pages['url']) )
          end
        end

        def pages_collection_name
          @_pages_collection_name ||= [Scruber::Mongo.configuration.options['collections_prefix'], @options[:scraper_name], 'pages'].select(&:present?).map(&:to_s).join('_')
        end

    end
  end
end

Scruber::Queue.add_adapter(:mongo, Scruber::QueueAdapters::Mongo)