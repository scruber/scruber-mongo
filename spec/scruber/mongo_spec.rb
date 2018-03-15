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
end
