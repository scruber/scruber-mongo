require "spec_helper"

RSpec.describe Scruber::Core::Extensions::MongoOutput do
  before { described_class.register }

  describe "register" do
    it "should extend Scruber::MongoOutput with mongo_out and mongo_find methods" do
      expect(Scruber::Core::Crawler.method_defined?(:mongo_find)).to be_truthy
      expect(Scruber::Core::Crawler.method_defined?(:mongo_out)).to be_truthy
      expect(Scruber::Core::Crawler._registered_method_missings.keys.include?(/\Amongo_out_(\w+)\Z/)).to be_truthy
      expect(Scruber::Core::Crawler._registered_method_missings.keys.include?(/\Amongo_find_(\w+)\Z/)).to be_truthy
      expect(Scruber::Core::Crawler.new(:sample).respond_to?(:mongo_out_product)).to be_truthy
      expect(Scruber::Core::Crawler.new(:sample).respond_to?(:mongo_find_product)).to be_truthy
    end
  end

  describe "#mongo_out" do
    it "should create record in scruber_sample_records" do
      Scruber.run :sample do
        mongo_out name: 'Test'
      end
      expect(Scruber::Mongo.client[:scruber_sample_records].find.first[:name]).to eq('Test')
    end

    it "should create record in scruber_sample_product" do
      Scruber.run :sample do
        mongo_out_product title: 'Soap'
      end
      expect(Scruber::Mongo.client[:scruber_sample_product].count).to eq(1)
      expect((Scruber::Mongo.client[:scruber_sample_product].find.first[:title] rescue nil)).to eq('Soap')
    end

    it "should create 3 records in scruber_sample_product" do
      Scruber.run :sample do
        (1..3).each do |i|
          mongo_out_product title: "Soap #{i}"
        end
      end
      expect(Scruber::Mongo.client[:scruber_sample_product].count).to eq(3)
      expect(Scruber::Mongo.client[:scruber_sample_product].find.to_a.map{|t| t[:title]}.sort).to eq(["Soap 1", "Soap 2", "Soap 3"])
    end

    it "should return id of document on new insert" do
      Scruber.run :sample do
        $id = mongo_out_product title: 'TestID1'
      end
      expect(Scruber::Mongo.client[:scruber_sample_product].find({_id: $id}).first[:title]).to eq('TestID1')
    end

    it "should return id of document on update" do
      Scruber.run :sample do
        $id = mongo_out_product id: 'abc', title: 'TestID2'
      end
      expect(Scruber::Mongo.client[:scruber_sample_product].find({_id: $id}).first[:title]).to eq('TestID2')
    end
  end

  describe "#mongo_find" do
    it "should find record in scruber_sample_records" do
      Scruber.run :sample do
        mongo_out name: 'Test', _id: 'test1'

        $record = mongo_find 'test1'
      end
      expect($record[:name]).to eq('Test')
    end

    it "should find record in scruber_sample_product" do
      Scruber.run :sample do
        mongo_out_product title: 'Soap', _id: 'test2'

        $record = mongo_find_product 'test2'
      end
      expect($record[:title]).to eq('Soap')
    end

    it "should find record by custom query" do
      Scruber.run :sample do
        mongo_out_product title: 'iPhone'

        $record = mongo_find_product title: 'iPhone'
      end
      expect($record.first[:title]).to eq('iPhone')
    end

    it "should create 3 records in scruber_sample_product" do
      Scruber.run :sample do
        $titles = []
        (1..3).each do |i|
          mongo_out_product title: "Soap #{i}", _id: "soap#{i}"

          $titles.push mongo_find_product("soap#{i}")[:title]
        end
      end
      expect($titles).to eq(["Soap 1", "Soap 2", "Soap 3"])
    end
  end

  describe "#mongo_collection" do
    it "should return default collection" do
      Scruber.run :sample do
        mongo_out name: 'Test'

        $collection = mongo_collection
      end
      expect($collection.name).to eq("scruber_sample_#{Scruber::Core::Extensions::MongoOutput.default_suffix_name}")
    end

    it "should return products collection" do
      Scruber.run :sample do
        $collection = mongo_products_collection
      end
      expect($collection.name).to eq("scruber_sample_products")
    end

    it "should return products collection twice" do
      Scruber.run :sample do
        $collection = mongo_products_collection
        $collection = mongo_products_collection
      end
      expect($collection.name).to eq("scruber_sample_products")
    end
  end

end
