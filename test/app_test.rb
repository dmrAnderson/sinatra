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

  def test_successful_signup
    User.dataset.delete

    post '/signup', email: 'test@example.com', password: 'secret123'

    assert_equal 200, last_response.status
    assert_equal 'User created', last_response.body
    assert_equal 1, User.count
    user = User.first
    assert_equal 'test@example.com', user.email
    assert user.valid_password?('secret123')
  end

  def test_signup_with_missing_email
    post '/signup', email: 'test@example.com', password: 'secret123'

    assert_equal 422, last_response.status
    assert_equal 'Signup failed', last_response.body
    assert_equal 1, User.count

    User.dataset.delete
  end
end
