# frozen_string_literal: true

require 'sinatra'
require 'sequel'

set :environment, ENV.fetch('RACK_ENV', 'development')
set :database_url, ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app')
set :database, Sequel.connect(settings.database_url)
set :session_secret, ENV.fetch('SUPER_SECRET_KEY', settings.database_url * 2)

require './models/user'
require './models/post'
require './models/plan'

set :plans, Plan.all

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

  def authenticate!
    redirect '/login' unless logged_in?
  end

  def not_authenticated!
    redirect '/' if logged_in?
  end
end

get '/' do
  authenticate!
  @posts = current_user.posts
  erb :index, layout: :application
end

get '/signup' do
  not_authenticated!
  erb :signup, layout: :application
end

post '/signup' do
  not_authenticated!
  user = User.new(email: params[:email])
  user.password = params[:password]
  if user.valid?
    user.save
    login(user)
    redirect '/'
  else
    status 422
    erb :signup, layout: :application
  end
end

get '/login' do
  not_authenticated!
  erb :login, layout: :application
end

post '/login' do
  not_authenticated!
  user = User.first(email: params[:email])
  if user && user.valid_password?(params[:password])
    login(user)
    redirect '/'
  else
    status 422
    erb :login, layout: :application
  end
end

get '/logout' do
  authenticate!
  logout
  redirect '/login'
end

get '/posts/new' do
  authenticate!
  @post = Post.new
  erb :new_post, layout: :application
end

post '/posts' do
  authenticate!
  @post = Post.new(title: params[:title], content: params[:content])
  @post.user_id = current_user.id
  if @post.valid?
    @post.save
    redirect '/'
  else
    status 422
    erb :new_post, layout: :application
  end
end

get '/posts/:id/edit' do
  authenticate!
  @post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if @post
    erb :edit_post, layout: :application
  else
    halt 404
  end
end

patch '/posts/:id' do
  authenticate!
  @post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if @post
    @post.title = params[:title]
    @post.content = params[:content]
    if @post.valid?
      @post.save
      redirect '/'
    else
      status 422
      erb :edit_post, layout: :application
    end
  else
    halt 404
  end
end

delete '/posts/:id' do
  authenticate!
  @post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if @post
    @post.delete
    redirect '/'
  else
    halt 404
  end
end
