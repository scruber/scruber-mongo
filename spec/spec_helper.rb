require "bundler/setup"
require 'webmock/rspec'
require "scruber/mongo"
require 'database_cleaner'

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end
Mongo::Logger.level = 1
Scruber::Mongo.configuration.load!(file_path('config.yml'))

Dir[Gem.loaded_specs['scruber'].full_gem_path+"/spec/support/**/*.rb"].each { |f| require f }

Scruber::Helpers::UserAgentRotator.configure do
  add "Scruber 1.0", tags: [:robot, :scruber]
  add "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36", tags: [:desktop, :chrome, :macos]
end

Scruber.configure do |config|
  config.fetcher_adapter = :typhoeus_fetcher
  config.fetcher_options = {
    max_concurrency: 1,
    max_retry_times: 5,
    retry_delays: [1,2,2,4,4],
    followlocation: false,
    request_timeout: 15,
  }
  config.fetcher_agent_adapter = :memory
  config.fetcher_agent_options = {}
  config.queue_adapter = :memory
  config.queue_options = {}
end

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
