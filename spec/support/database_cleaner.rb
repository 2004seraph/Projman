# frozen_string_literal: true

RSpec.configure do |config|
  # Inspired by
  # https://betterprogramming.pub/how-to-set-up-rails-with-rspec-capybara-and-database-cleaner-aacb000070ef

  # bomb the test database before every single test suite
  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation, except: %w(ar_internal_metadata)
  end

  config.before(:each) do
    # during a test suite, mirror RSpec database transaction behaviour between tests.
    DatabaseCleaner.strategy = :transaction
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
