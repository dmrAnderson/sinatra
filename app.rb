# frozen_string_literal: true

require 'sinatra'
require 'sequel'

set :environment, ENV.fetch('RACK_ENV', 'development')
set :database_url, ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app')
set :database, Sequel.connect(settings.database_url)



get '/' do
  'Hello from Sinatra'
end
