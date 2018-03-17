RSpec.describe Scruber::Mongo do
  it "has a version number" do
    expect(Scruber::Mongo::VERSION).not_to be nil
  end

  it "loaded default configuration" do
    expect(Scruber::Mongo.configuration.configured?).to be_truthy
  end

  it "has connection to mongo" do
    expect(Scruber::Mongo.client.database.name).to be(Scruber::Mongo.configuration.clients[:default]['database'])
  end

  context "run scraper with mongo queue" do
    context "complex example" do
      it "should parse pages in 2 steps" do
        stub_request(:get, "http://example.com/catalog").to_return(body: '<div><a href="/product1">Product 1</a><a href="/product2">Product 2</a><a href="/product3">Product 3</a></div>')
        stub_request(:get, "http://example.com/product1").to_return(body: '<div><h1>Product 1</h1></div>')
        stub_request(:get, "http://example.com/product2").to_return(body: '<div><h1>Product 2</h1></div>')
        stub_request(:get, "http://example.com/product3").to_return(body: '<div><h1>Product 3</h1></div>')

        $products = []
        Scruber.run :sample do
          get "http://example.com/catalog"
          
          parse :html do |page, doc|
            doc.search('a').each do |a|
              get_product URI.join(page.url, a.attr('href')).to_s
            end
          end

          parse_product :html do |page,doc|
            $products.push doc.at('h1').text
          end
        end
        expect($products.sort).to eq((1..3).map{|i| "Product #{i}"}.sort)
      end

      it "should redownload page" do
        stub_request(:get, "http://example.com/").to_return(body: '<div>blocked</div>').times(1).then.to_return(body: '<div><h1>Product</h1></div>')

        Scruber.run :sample do
          get "http://example.com/"
          
          parse :html do |page, doc|
            if page.response_body =~ /blocked/
              page.redownload!
            else
              $title = doc.at('h1').text
            end
          end
        end
        expect($title).to eq('Product')
      end
    end
  end
end
