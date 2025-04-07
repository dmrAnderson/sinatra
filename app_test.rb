# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require './app'
require 'minitest/autorun'
require 'rack/test'

# Load the Sinatra app

class AppTest < Minitest::Test
  include Rack::Test::Methods

  # Helper method to access Sinatra's application instance
  def app
    Sinatra::Application
  end

  def test_app
    get '/'
    assert last_response.ok?
    assert_equal 'Hello from Sinatra', last_response.body.strip
  end
end
