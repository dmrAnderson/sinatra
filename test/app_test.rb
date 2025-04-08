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
    get '/'

    assert last_response.ok?
    assert_equal 'Hello from Sinatra', last_response.body.strip
    assert_equal 'text/html;charset=utf-8', last_response.content_type
  end

  def test_authentication
    User.dataset.delete

    post '/signup', email: 'test@example.com', password: 'secret123'

    assert_equal 200, last_response.status
    assert_equal 'User created', last_response.body
    assert_equal 1, User.count
    user = User.first
    assert_equal 'test@example.com', user.email
    assert user.valid_password?('secret123')
    assert_equal user.id, last_request.env['rack.session'][:user_id]

    post '/signup', email: 'test@example.com', password: 'secret123'

    assert_equal 422, last_response.status
    assert_equal 'Signup failed', last_response.body

    delete '/logout'

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/login', last_response.location
    assert_nil last_request.env['rack.session'][:user_id]

    post '/login'

    assert_equal 401, last_response.status
    assert_equal 'Invalid credentials', last_response.body

    post '/login', email: 'test@example.com', password: 'secret123'

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response.location
    assert_equal user.id, last_request.env['rack.session'][:user_id]
  end
end
