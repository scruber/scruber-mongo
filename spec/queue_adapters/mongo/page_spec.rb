require "spec_helper"

RSpec.describe Scruber::QueueAdapters::Mongo::Page do

  describe "page" do
    let(:page) { described_class.new(nil, 'http://example.com') }

    it 'should have valid url' do
      expect(page.url).to eq('http://example.com')
    end

    it 'should have url in attrs' do
      expect(page.attrs[:url]).to eq('http://example.com')
      expect(page.attrs[:method]).to eq(:get)
    end

    it 'should change url in attrs' do
      page.url = 'http://abc.com'
      expect(page.attrs[:url]).to eq('http://abc.com')
    end

  end

end
