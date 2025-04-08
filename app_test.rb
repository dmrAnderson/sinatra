# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] = 'postgres://postgres:postgres@localhost:5432/sinatra_app'

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
end
