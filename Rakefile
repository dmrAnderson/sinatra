# frozen_string_literal: true

require 'sequel'
require 'sequel/extensions/migration'

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app'))

namespace :db do
  task :migrate do
    Sequel::Migrator.run(DB, 'db/migrations')
    puts "✅ Migrations applied"
  end

  task :rollback do
    Sequel::Migrator.run(DB, 'db/migrations', target: 0)
    puts "✅ Migrations rolled back"
  end
end
