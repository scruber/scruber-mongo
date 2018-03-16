require "spec_helper"

RSpec.describe Scruber::Helpers::FetcherAgentAdapters::Mongo do

  let(:cookie_jar_string) { "---\n- !ruby/object:HTTP::Cookie\n  name: feed_flow\n  value: top\n  domain: example.com\n  for_domain: false\n  path: \"/\"\n  secure: false\n  httponly: true\n  expires: \n  max_age: 26784000\n  created_at: #{Time.now.strftime('%Y-%m-%d')} 16:46:15.443984000 +03:00\n  accessed_at: #{Time.now.strftime('%Y-%m-%d')} 16:47:07.047296000 +03:00\n" }

  let(:agent) do
    described_class.new user_agent: 'Scruber',
                        proxy_id: 1,
                        headers: {'a' => 1},
                        cookie_jar: cookie_jar_string,
                        disable_proxy: true
  end

  describe "#initialize" do
    it "should not generate id" do
      expect(agent.id).to be_nil
    end
  end

  describe "#save" do
    context "without id" do
      it "should be stored to collection" do
        agent.save
        expect(Scruber::Helpers::FetcherAgentAdapters::Mongo.find(agent.id)).not_to be_nil
      end

      it "should be updated" do
        agent.save
        agent.user_agent = 'Mozilla'
        agent.save
        expect(Scruber::Helpers::FetcherAgentAdapters::Mongo.find(agent.id).user_agent).to eq('Mozilla')
      end
    end

    context "with id" do
      it "should be stored to collection" do
        agent.id = 1
        agent.save
        expect(Scruber::Helpers::FetcherAgentAdapters::Mongo.find(1)).not_to be_nil
      end

      it "should be updated" do
        agent.id = 1
        agent.save
        agent.user_agent = 'Mozilla'
        agent.save
        expect(Scruber::Helpers::FetcherAgentAdapters::Mongo.find(1).user_agent).to eq('Mozilla')
      end
    end
  end

  describe "delete" do
    it "should be deleted from collection" do
      agent.save
      expect(Scruber::Helpers::FetcherAgentAdapters::Mongo.find(agent.id)).not_to be_nil
      agent.delete
      expect(Scruber::Helpers::FetcherAgentAdapters::Mongo.find(agent.id)).to be_nil
    end
  end

end
