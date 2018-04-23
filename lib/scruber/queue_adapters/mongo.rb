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

        # 
        # Mark page as processed by parser and save it
        # 
        # @return [void]
        def processed!
          # Monkey patch for processing error pages.
          if @fetched_at == 0
            @fetched_at = -1
          end
          super
        end

        # 
        # Generating hash with mongo doc attributes
        # 
        # @return [Hash] hash with page attributes
        def attrs
          @options.with_indifferent_access.except('id', '_id').merge(id.present? ? {_id: id} : {}).merge (instance_variables.select{|ivar| !(ivar.to_s =~ /\@_/) }-[:@options, :@queue]).inject({}){|acc,ivar| acc[ivar[1..-1]] = instance_variable_get(ivar);acc }.with_indifferent_access
        end

        # 
        # Delete record from Mongo collection
        # 
        # @return [void]
        def delete
          @queue.collection.find({"_id" => self.id }).delete_one if self.id.present?
        end
      end

      # 
      # Add page to queue
      # @param url [String] URL of page
      # @param options [Hash] Other options, see {Scruber::QueueAdapters::AbstractAdapter::Page}
      # 
      # @return [void]
      def add(url_or_page, options={})
        if url_or_page.is_a?(Page)
          url_or_page.queue = self
          url_or_page.save({new: true}.merge(options))
        else
          Page.new(self, options.merge(url: url_or_page)).save({new: true})
        end
      end
      alias_method :push, :add

      # 
      # Size of queue
      # 
      # @return [Integer] count of pages in queue
      def size
        collection.count
      end

      # 
      # Count of downloaded pages
      # Using to show downloading progress.
      # 
      # @return [Integer] count of downloaded pages
      def downloaded_count
        collection.find({fetched_at: {"$gt" => 0}}).count
      end

      # 
      # Search page by id
      # @param id [Object] id of page
      # 
      # @return [Page] page object
      def find(id)
        build_pages collection.find({_id: id}).first
      end

      # 
      # Fetch downloaded and not processed pages for feching
      # @param count=nil [Integer] count of pages to fetch
      # 
      # @return [Scruber::QueueAdapters::AbstractAdapter::Page|Array<Scruber::QueueAdapters::AbstractAdapter::Page>] page of count = nil, or array of pages of count > 0
      def fetch_downloaded(count=nil)
        if count.nil?
          build_pages collection.find({fetched_at: {"$gt" => 0}, processed_at: 0}).first
        else
          build_pages collection.find({fetched_at: {"$gt" => 0}, processed_at: 0}).limit(count).to_a
        end
      end

      # 
      # Fetch pending page for fetching
      # @param count=nil [Integer] count of pages to fetch
      # 
      # @return [Scruber::QueueAdapters::AbstractAdapter::Page|Array<Scruber::QueueAdapters::AbstractAdapter::Page>] page of count = nil, or array of pages of count > 0
      def fetch_pending(count=nil)
        if count.nil?
          build_pages collection.find({fetched_at: 0, retry_count: {"$lt" => ::Scruber.configuration.fetcher_options[:max_retry_times]}, retry_at: {"$lte" => Time.now.to_i}}).first
        else
          build_pages collection.find({fetched_at: 0, retry_count: {"$lt" => ::Scruber.configuration.fetcher_options[:max_retry_times]}, retry_at: {"$lte" => Time.now.to_i}}).limit(count).to_a
        end
      end

      # 
      # Fetch error page
      # @param count=nil [Integer] count of pages to fetch
      # 
      # @return [Scruber::QueueAdapters::AbstractAdapter::Page|Array<Scruber::QueueAdapters::AbstractAdapter::Page>] page of count = nil, or array of pages of count > 0
      def fetch_error(count=nil)
        if count.nil?
          build_pages collection.find({fetched_at: 0, retry_count: {"$gte" => ::Scruber.configuration.fetcher_options[:max_retry_times]}}).first
        else
          build_pages collection.find({fetched_at: 0, retry_count: {"$gte" => ::Scruber.configuration.fetcher_options[:max_retry_times]}}).limit(count).to_a
        end
      end

      # 
      # Used by Core. It checks for pages that are
      # not downloaded or not parsed yet.
      # 
      # @return [Boolean] true if queue still has work for scraper
      def has_work?
        fetch_pending.present? || fetch_downloaded.present?
      end

      # 
      # Accessing to mongo collection instance
      # 
      # @return [Mongo::Collection] Mongo collection instance
      def collection
        Scruber::Mongo.client[pages_collection_name]
      end

      # 
      # Check if queue was initialized.
      # Using for `seed` method. If queue was initialized,
      # then no need to run seed block.
      # 
      # @return [Boolean] true if queue already was initialized
      def initialized?
        Scruber::Mongo.client[pages_collection_name].find.first.present?
      end

      private

        # 
        # Wrapping mongo objects into queue Page objects
        # 
        # @param pages [Hash|Array<Hash>] Mongo document or array of mongo documents
        # 
        # @return [type] [description]
        def build_pages(pages)
          if pages.nil?
            nil
          elsif pages.is_a?(Array)
            pages.map{|p| Page.new(self, p.with_indifferent_access.merge(url: p['url']) )}
          else
            Page.new(self, pages.with_indifferent_access.merge(url: pages['url']) )
          end
        end

        # 
        # Generating mongo pages collection name
        # 
        # @return [String] name of pages collection
        def pages_collection_name
          @_pages_collection_name ||= [Scruber::Mongo.configuration.options['collections_prefix'], @options[:scraper_name], 'pages'].select(&:present?).map(&:to_s).join('_')
        end

    end
  end
end

Scruber::Queue.add_adapter(:mongo, Scruber::QueueAdapters::Mongo)