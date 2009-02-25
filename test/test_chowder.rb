require File.join(File.dirname(__FILE__), 'helpers')

class MyApp < Sinatra::Base
  disable :sessions
  get '/' do
    redirect '/login' unless session[:current_user]
    "protected area"
  end
end

class TestChowder < Test::Unit::TestCase
  before do
    @app = Rack::Builder.new {
      use Chowder do |login, password|
        login == "harry" && password == "clam"
      end
      run MyApp
    }
  end

  test "shows login page" do
    get '/login'
    assert_match /Login/, body
  end

  test "redirects unauthenticated requests to login" do
    get '/'
    follow!
    assert_match /Login/, body
  end

  test "allows authenticated requests" do
    get '/', :env => {:session => {'current_user' => 'foo'}}

  end
end
