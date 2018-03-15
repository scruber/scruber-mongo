require "spec_helper"

RSpec.describe Scruber::QueueAdapters::Mongo do
  let(:queue){ described_class.new }

  it "queue page for downloading" do
    queue.add "http://example.com"
    expect(queue.queue_size).to eq(1)
  end

  it "shift enqueued page" do
    queue.add "http://example.com"
    page = queue.fetch_pending
    expect(page.url).to eq("http://example.com")
  end

  it "should update page" do
    queue.add "http://example.com"
    page = queue.fetch_pending
    page.url = "http://example.net"
    page.save
    page = queue.fetch_pending
    expect(page.url).to eq("http://example.net")
  end

  it "should update page and fetch downloaded page" do
    queue.add "http://example.com"
    page = queue.fetch_pending
    page.fetched_at = Time.now.to_i
    page.save
    pending_page = queue.fetch_pending
    downloaded_page = queue.fetch_downloaded
    expect(pending_page).to eq(nil)
    expect(downloaded_page.url).to eq("http://example.com")
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
end
