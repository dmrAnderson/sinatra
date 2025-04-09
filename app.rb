# frozen_string_literal: true

require 'sinatra'
require 'sequel'

set :environment, ENV.fetch('RACK_ENV', 'development')
set :database_url, ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app')
set :database, Sequel.connect(settings.database_url)
set :session_secret, ENV.fetch('SUPER_SECRET_KEY', settings.database_url * 2)

require './models/user'
require './models/post'
require './models/subscription'
require './models/plan'

set :plans, Plan.all

enable :sessions

helpers do
  def current_user
    return unless session[:user_id]

    @current_user ||= User[session[:user_id]]
  end

  def current_subscription
    return unless current_user

    @current_subscription ||= Subscription.association_join(:plan).first(deactivated_at: nil, user_id: current_user.id)
  end

  def current_plan
    return unless current_subscription

    @current_plan ||= Plan[current_subscription.plan_id]
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

  def permissions(plan)
    {
      Post => {
        read: plan >= Plan::BASIC,
        create: plan >= Plan::STANDARD,
        update: plan >= Plan::STANDARD,
        delete: plan >= Plan::STANDARD
      }
    }
  end

  def authorized?(*actions, plan: current_plan&.type.to_i)
    permissions(plan).dig(*actions)
  end

  def authorize!(*actions, plan: current_plan&.type.to_i)
    authorized?(*actions, plan: plan) || halt(403)
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

get '/subscriptions/new' do
  authenticate!
  erb :subscription_new, layout: :application
end

post '/subscriptions' do
  authenticate!
  halt 403 if current_subscription && !current_subscription.expired?
  subscription = Subscription.new(user_id: current_user.id, plan_id: params[:plan_id])
  if subscription.valid?
    subscription.save
    redirect '/'
  else
    status 422
    erb :subscription_new, layout: :application
  end
end

get '/posts' do
  authenticate!
  authorize!(Post, :read)
  @posts = Post.all
  erb :posts, layout: :application
end

get '/posts/new' do
  authenticate!
  authorize!(Post, :create)
  @post = Post.new
  erb :post_new, layout: :application
end

post '/posts' do
  authenticate!
  authorize!(Post, :create)
  @post = Post.new(title: params[:title], content: params[:content])
  @post.user_id = current_user.id
  if @post.valid?
    @post.save
    redirect '/'
  else
    status 422
    erb :post_new, layout: :application
  end
end

get '/posts/:id/edit' do
  authenticate!
  authorize!(Post, :update)
  @post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if @post
    erb :post_edit, layout: :application
  else
    halt 404
  end
end

patch '/posts/:id' do
  authenticate!
  authorize!(Post, :update)
  @post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if @post
    @post.title = params[:title]
    @post.content = params[:content]
    if @post.valid?
      @post.save
      redirect '/'
    else
      status 422
      erb :post_edit, layout: :application
    end
  else
    halt 404
  end
end

delete '/posts/:id' do
  authenticate!
  authorize!(Post, :delete)
  @post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if @post
    @post.delete
    redirect '/'
  else
    halt 404
  end
end
