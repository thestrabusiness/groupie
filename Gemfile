# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.5"

gem "clearance"
gem "dotenv-rails"
gem "foreman", require: false
gem "jbuilder", "~> 2.7"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 4.1"
gem "rails", "~> 6.0.3", ">= 6.0.3.2"
gem "rubocop", "0.80.0", require: false
gem "sass-rails", ">= 6"
gem "webpacker", "~> 4.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

group :development, :test do
  gem "pry"
  gem "rspec-rails"
end

group :development do
  gem "listen", "~> 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "web-console", ">= 3.3.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
