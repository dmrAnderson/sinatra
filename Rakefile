# frozen_string_literal: true

require 'sequel'
require 'sequel/extensions/migration'

namespace :db do
  task :migrate do
    DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app'))
    Sequel::Migrator.run(DB, 'db/migrations')
    puts "✅ Migrations applied"
  end
end
