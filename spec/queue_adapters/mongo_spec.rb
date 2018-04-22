require "spec_helper"

RSpec.describe Scruber::QueueAdapters::Mongo do
  let(:queue){ described_class.new scraper_name: 'test' }

  it_behaves_like "queue_adapter"


  it "should have correct mongo collection name" do
    Scruber::Mongo.client['scruber_test_pages'].drop
    queue.add "http://example.com"
    expect(Scruber::Mongo.client['scruber_test_pages'].count).to eq(1)
  end

  it "shift enqueued page" do
    queue.add "http://example.com"
    page = queue.fetch_pending
    expect(page.url).to eq("http://example.com")
  end

  context "#save" do
    it "should find page by id" do
      queue.add "http://example.com"
      page = queue.fetch_pending
      
      found_page = queue.find page.id
      expect(found_page.url).to eq(page.url)
    end

    it "should save page with provided id" do
      queue.add "http://example.abc", _id: 'abc'
      page = queue.find 'abc'
      queue.add "http://example.def", id: 'def'
      page2 = queue.find 'def'
      
      expect(page.url).to eq("http://example.abc")
      expect(page2.url).to eq("http://example.def")
    end

    it "should delete page" do
      queue.add "http://example.abc", _id: 'abc'
      page = queue.find 'abc'
      page.delete
      
      expect(queue.find('abc')).to eq(nil)
    end
  end

  context "#processed!" do
    it "should update page and set processed_at" do
      queue.add "http://example.com"
      page = queue.fetch_pending
      page.fetched_at = Time.now.to_i
      page.save
      downloaded_page = queue.fetch_downloaded
      downloaded_page.processed!
      downloaded_page2 = queue.fetch_downloaded
      expect(downloaded_page2).to eq(nil)
      downloaded_page = queue.collection.find({_id: downloaded_page.id}).first
      expect(downloaded_page[:processed_at]).to be > 0
    end
  end
end
