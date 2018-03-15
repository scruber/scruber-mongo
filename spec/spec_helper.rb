require "bundler/setup"
require "scruber/mongo"
require 'database_cleaner'

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end
Mongo::Logger.level = 1
Scruber::Mongo.configuration.load!(file_path('config.yml'))

DatabaseCleaner[:mongo].strategy = :truncation
DatabaseCleaner[:mongo].db = Scruber::Mongo.client.database

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :progress # :documentation, :html, :textmate

  config.before :each do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
