# frozen_string_literal: true

require 'sinatra'
require 'sequel'
require 'sequel/extensions/migration'
require 'stripe'
require 'json'
require 'i18n'

Stripe.api_key = ENV.fetch('STRIPE_API_KEY')
Stripe.log_level = Stripe::LEVEL_INFO

I18n.load_path += Dir[File.expand_path("config/locales") + "/*.yml"]
I18n.available_locales = [:en, :ua]
I18n.default_locale = :en

set :environment, ENV.fetch('RACK_ENV', 'development')
set :database_url, ENV.fetch('DATABASE_URL', 'postgres://postgres:postgres@localhost:5432/sinatra_app')
set :database, Sequel.connect(settings.database_url, logger: Logger.new('log/db.log'))
set :session_secret, ENV.fetch('SUPER_SECRET_KEY', settings.database_url * 2)

Sequel::Migrator.run(settings.database, 'db/migrations')

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

    @current_subscription ||= Subscription.first(deactivated_at: nil, user_id: current_user.id)
  end

  def current_plan
    return unless current_subscription

    @current_plan ||= Plan[current_subscription.plan_id]
  end

  def subscribed?
    !!current_subscription
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
      Subscription => {
        read: true,
        create: true,
        delete: true
      },
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

  def authorize!(*actions)
    authorized?(*actions) || halt(403)
  end

  def current_locale
    @current_locale ||= current_user&.localization&.to_sym
  end

  def current_locale=(locale)
    current_user.update(localization: locale)
    @current_locale = locale.to_sym
  end

  def create_stripe_customer(user)
    return if ENV.fetch('RACK_ENV') == 'test'

    Stripe::Customer.create(
      email: user.email,
      name: user.email.split('@')[0],
      description: "Customer for #{user.email}",
      metadata: {
        user_id: user.id
      }
    )
  rescue Stripe::StripeError => e
    puts "Stripe error: #{e.message}"
  end
end

before do
  if subscribed? && current_subscription.expired?
    current_subscription.deactivate
    @current_subscription = nil
  end

  I18n.locale = current_locale if current_locale
end

post '/locale' do
  authenticate!

  locale = params[:locale].to_s

  p '-----------1'
  return halt 400 if locale.empty?
  p '-----------2'
  return halt 422 unless I18n.available_locales.include?(locale.to_sym)
  p '-----------3'

  p "-----------#{locale}"
  self.current_locale = locale if current_locale != locale
  p "-----------#{current_locale}"

  redirect request.referer || '/'
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
    create_stripe_customer(user)
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

get '/subscriptions' do
  authenticate!
  authorize!(Subscription, :read)
  @subscriptions = Subscription.association_join(:plan).where(user_id: current_user.id)
  erb :subscriptions, layout: :application
end

get '/subscription' do
  authenticate!
  authorize!(Subscription, :read)
  halt 403 unless subscribed?

  session = Stripe::BillingPortal::Session.create(
    customer: current_user.stripe_customer_id,
    return_url: 'http://localhost:4567/subscriptions'
  )

  redirect session.url
end

delete '/subscription' do
  authenticate!
  authorize!(Subscription, :delete)
  halt 403 unless subscribed?

  Stripe::Subscription.update(
    current_subscription.stripe_subscription_id,
    { cancel_at_period_end: true }
  )

  current_subscription.deactivate

  redirect '/'
end

post '/subscriptions' do
  authenticate!
  authorize!(Subscription, :create)
  halt 403 if subscribed?

  plan = Plan[params[:plan_id].to_i]

  product = Stripe::Product.list.detect { |product| product.metadata['plan_id'] == plan.id.to_s }
  price = Stripe::Price.list.find { |price| price.product == product.id }

  session = Stripe::Checkout::Session.create(
    customer: current_user.stripe_customer_id,
    line_items: [
      {
        price: price.id,
        quantity: 1,
      }
    ],
    mode: 'subscription',
    success_url: 'http://localhost:4567/subscriptions',
    cancel_url: 'http://localhost:4567/subscriptions',
  )

  redirect session.url
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
  post = Post.new(title: params[:title], content: params[:content])
  post.user_id = current_user.id
  if post.valid?
    post.save
    redirect '/'
  else
    @post = post
    status 422
    erb :post_new, layout: :application
  end
end

get '/posts/:id/edit' do
  authenticate!
  authorize!(Post, :update)
  post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if post
    @post = post
    erb :post_edit, layout: :application
  else
    halt 404
  end
end

patch '/posts/:id' do
  authenticate!
  authorize!(Post, :update)
  post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if post
    post.title = params[:title]
    post.content = params[:content]
    if post.valid?
      post.save
      redirect '/'
    else
      status 422
      @post = post
      erb :post_edit, layout: :application
    end
  else
    halt 404
  end
end

delete '/posts/:id' do
  authenticate!
  authorize!(Post, :delete)
  post = Post.first(id: [params[:id].to_i], user_id: current_user.id)
  if post
    post.delete
    redirect '/'
  else
    halt 404
  end
end

post '/stripe/webhooks' do
  endpoint_secret = 'whsec_3f5902a4cbc5005516d25b2d37362cf191f23722e6616b261b598c1db72a4eb4'
  payload = request.body.read

  begin
    event = Stripe::Event.construct_from(
      JSON.parse(payload, symbolize_names: true)
    )
  rescue JSON::ParserError => e
    puts "⚠️  Webhook error while parsing basic request. #{e.message}"
    status 400
    return
  end

  if endpoint_secret
    signature = request.env['HTTP_STRIPE_SIGNATURE']

    begin
      event = Stripe::Webhook.construct_event(
        payload, signature, endpoint_secret
      )
    rescue Stripe::SignatureVerificationError => e
      puts "⚠️  Webhook signature verification failed. #{e.message}"
      status 400
    end
  end

  case event.type
  when 'customer.created'
    customer = event.data.object
    User.first(email: customer.email).update(stripe_customer_id: customer.id)
  when 'invoice.payment_succeeded'
    invoice = event.data.object


    plan_id = Stripe::Product.retrieve(invoice.lines.data[0].pricing.price_details.product).metadata['plan_id']
    user_id = Stripe::Customer.retrieve(invoice.customer).metadata['user_id']
    hosted_invoice_url = invoice.hosted_invoice_url
    stripe_subscription_id = invoice.parent.subscription_details.subscription

    subscription = Subscription.new(
      user_id: user_id,
      plan_id: plan_id,
      stripe_subscription_id: stripe_subscription_id,
      hosted_invoice_url: hosted_invoice_url)
    subscription.save
  else
    puts "Unhandled event type: #{event.type}"
  end
  status 200
end
