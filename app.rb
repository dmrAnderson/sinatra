# frozen_string_literal: true

require 'sinatra'
require 'sequel'

set :environment, ENV.fetch('RACK_ENV', 'development')
set :database_url, ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app')
set :database, Sequel.connect(settings.database_url)
set :session_secret, ENV.fetch('SUPER_SECRET_KEY', settings.database_url * 2)

require './models/user'

enable :sessions

helpers do
  def current_user
    @current_user ||= User[session[:user_id]] if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def login(user)
    session[:user_id] = user.id
  end

  def logout
    session[:user_id] = nil
  end
end

get '/' do
  'Hello from Sinatra'
end

post '/signup' do
  user = User.new(email: params[:email])
  user.password = params[:password]
  if user.valid?
    user.save
    login(user)
    "User created"
  else
    status 422
    "Signup failed"
  end
end

post '/login' do
  user = User.where(email: params[:email]).first
  if user && user.valid_password?(params[:password])
    login(user)
    redirect '/'
  else
    status 401
    "Invalid credentials"
  end
end

delete '/logout' do
  logout
  redirect '/login'
end
