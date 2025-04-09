# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require './app'
require 'minitest/autorun'
require 'rack/test'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def cleanup_db
    Sequel::Model.db.transaction(rollback: :always) do
      Sequel::Model.db.run('TRUNCATE TABLE users, posts, subscriptions, plans CASCADE')
      yield
    end
  end

  def test_root
    cleanup_db do
      get '/'

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')
      user.add_post(title: 'Test Post', content: 'This is a test post.')

      get '/', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type
    end
  end

  def test_signup
    cleanup_db do
      user = User.create(email: 'test@example.com', password: 'secret123')

      get '/signup', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location

      get '/signup', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post '/signup', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location

      post '/signup', { email: '', password: '' }, { 'rack.session' => { user_id: nil } }

      assert_equal 422, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      User.dataset.delete

      post '/signup', email: 'test@example.com', password: 'secret123'

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location
      assert_equal 1, User.count
    end
  end

  def test_login
    cleanup_db do
      user = User.create(email: 'test@example.com', password: 'secret123')

      get '/login', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location

      get '/login', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post '/login', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location

      post '/login', { email: '', password: '' }, { 'rack.session' => { user_id: nil } }

      assert_equal 422, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post '/login', email: 'test@example.com', password: 'secret123'

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location
      assert_equal user.id, last_request.env['rack.session'][:user_id]
    end
  end

  def test_logout
    cleanup_db do
      user = User.create(email: 'test@example.com', password: 'secret123')

      get '/logout', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      get '/logout', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location
      assert_nil last_request.env['rack.session'][:user_id]
    end
  end

  def test_subscription_new
    test_logout do
      get '/subscriptions/new', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')

      get '/subscriptions/new', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type
    end
  end

  def test_subscription_create
    test_logout do
      post '/subscriptions', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')
      plan = Plan.create(name: 'Basic', type: 10, description: 'Basic plan', price: 10)

      post '/subscriptions', { plan_id: '' }, { 'rack.session' => { user_id: user.id } }

      assert_equal 422, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post '/subscriptions', { plan_id: plan.id }, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location
      assert_equal 1, Subscription.count

      user.add_subscription(plan_id: plan.id)

      post '/subscriptions', { plan_id: plan.id }, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type
    end
  end

  def test_post_index
    cleanup_db do
      get '/posts', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')
      user.add_post(title: 'Test Post', content: 'This is a test post.')


      get '/posts', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      plan = Plan.create(name: 'Basic', type: 10, description: 'Basic plan', price: 10)
      user.add_subscription(plan_id: plan.id)

      get '/posts', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type
    end
  end

  def test_post_new
    cleanup_db do
      get '/posts/new', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')

      get '/posts/new', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      plan = Plan.create(name: 'Standard', type: 20, description: 'Standard plan', price: 20)
      user.add_subscription(plan_id: plan.id)

      get '/posts/new', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type
    end
  end

  def test_post_create
    cleanup_db do
      post '/posts', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')

      post '/posts', { title: '', content: '' }, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      plan = Plan.create(name: 'Standard', type: 20, description: 'Standard plan', price: 20)
      user.add_subscription(plan_id: plan.id)

      post '/posts', { title: '', content: '' }, { 'rack.session' => { user_id: user.id } }

      assert_equal 422, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post '/posts', { title: 'Test Post', content: 'This is a test post.' }, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location
      assert_equal 1, Post.count
    end
  end

  def test_post_edit
    cleanup_db do
      get '/posts/1/edit', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')

      get '/posts/1/edit', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      plan = Plan.create(name: 'Standard', type: 20, description: 'Standard plan', price: 20)
      user.add_subscription(plan_id: plan.id)

      get '/posts/1/edit', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 404, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post = user.add_post(title: 'Test Post', content: 'This is a test post.')

      get "/posts/#{post.id}/edit", {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type
    end
  end

  def test_post_update
    cleanup_db do
      patch '/posts/1', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')

      patch '/posts/1', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      plan = Plan.create(name: 'Standard', type: 20, description: 'Standard plan', price: 20)
      user.add_subscription(plan_id: plan.id)

      patch '/posts/1', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 404, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post = user.add_post(title: 'Test Post', content: 'This is a test post.')

      patch "/posts/#{post.id}", { title: '', content: '' }, { 'rack.session' => { user_id: user.id } }

      assert_equal 422, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      patch "/posts/#{post.id}", { title: 'Updated Post', content: 'This is an updated post.' }, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location
    end
  end

  def test_post_delete
    cleanup_db do
      delete '/posts/1', {}, { 'rack.session' => { user_id: nil } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/login', last_response.location

      user = User.create(email: 'test@example.com', password: 'secret123')

      delete '/posts/1', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 403, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      plan = Plan.create(name: 'Standard', type: 20, description: 'Standard plan', price: 20)
      user.add_subscription(plan_id: plan.id)

      delete '/posts/1', {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 404, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.content_type

      post = user.add_post(title: 'Test Post', content: 'This is a test post.')

      delete "/posts/#{post.id}", {}, { 'rack.session' => { user_id: user.id } }

      assert_equal 302, last_response.status
      assert_equal 'http://example.org/', last_response.location
      assert_equal 0, Post.count
    end
  end
end
