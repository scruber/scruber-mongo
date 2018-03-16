module Scruber
  module Helpers
    module FetcherAgentAdapters
      class Mongo < AbstractAdapter
        def initialize(options={})
          options = options.with_indifferent_access
          super(options)
          @id = options.fetch(:_id){ options.fetch(:id){ nil } }
        end

        def attrs
          serialize_cookies
          {
            user_agent: @user_agent,
            proxy_id: @proxy_id,
            headers: @headers,
            cookie_jar: @cookie_jar,
            disable_proxy: @disable_proxy,
            updated_at: @updated_at,
            created_at: @created_at,
          }.merge((id.present? ? {_id: id} : {}))
        end

        def save
          @id = Scruber::Helpers::FetcherAgentAdapters::Mongo.store(self)
        end

        def delete
          Scruber::Helpers::FetcherAgentAdapters::Mongo.delete(self)
        end

        class << self
          def find(id)
            obj = mongo_collection.find({_id: id}).first
            obj.nil? ? nil : new(obj)
          end

          def mongo_collection
            Scruber::Mongo.client[agents_collection_name]
          end

          def agents_collection_name
            [Scruber::Mongo.configuration.options['collections_prefix'], 'fetcher_agents'].join('_')
          end

          def store(fetcher_agent, options={})
            if fetcher_agent.id.blank?
              mongo_collection.insert_one(fetcher_agent.attrs).inserted_id
            else
              mongo_collection.find_one_and_update(
                {"_id" => fetcher_agent.id },
                {'$set' => fetcher_agent.attrs },
                {return_document: :after, upsert: true}.merge(options)
              )[:_id]
            end
          end

          def delete(fetcher_agent)
            mongo_collection.find({_id: fetcher_agent.id}).delete_one
          end
        end

      end
    end
  end
end

Scruber::Helpers::FetcherAgent.add_adapter(:mongo, Scruber::Helpers::FetcherAgentAdapters::Mongo)