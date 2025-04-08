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

  def test_root
    User.dataset.delete

    get '/'

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/login', last_response.location

    user = User.create(email: 'test@example.com', password: 'secret123')

    get '/', {}, { 'rack.session' => { user_id: user.id } }

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response.content_type

    User.dataset.delete
  end

  def test_signup
    User.dataset.delete

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

    User.dataset.delete
  end

  def test_login
    User.dataset.delete

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

    User.dataset.delete
  end

  def test_logout
    User.dataset.delete

    user = User.create(email: 'test@example.com', password: 'secret123')

    get '/logout', {}, { 'rack.session' => { user_id: nil } }

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/login', last_response.location

    get '/logout', {}, { 'rack.session' => { user_id: user.id } }

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/login', last_response.location
    assert_nil last_request.env['rack.session'][:user_id]

    User.dataset.delete
  end
end
