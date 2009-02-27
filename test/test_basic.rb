require File.join(File.dirname(__FILE__), 'helpers')

class MyApp < Sinatra::Base
  get '/' do
    redirect '/login' unless session[:current_user]
    "protected area"
  end
end

class TestBasic < Test::Unit::TestCase
  before do
    @app = Rack::Builder.new {
      use Chowder::Basic do |login, password|
        login == "harry" && password == "clam"
      end
      run MyApp
    }
  end

  test "shows login page" do
    get '/login'
    assert_match /Login/, body
  end

  test "redirects on authentication success" do
    post '/login', :login => 'harry', 'password' => 'clam'
    assert_equal 302, status
    assert_equal '/', response.headers['Location']
  end

  test "redirects failed authentication attempts to login" do
    post '/login', :login => 'harry', 'password' => 'salad'
    assert_equal 302, status
    assert_equal '/login', response.headers['Location']
  end

  test "redirects to specified URL after login" do
    post '/login', {:login => 'harry', 'password' => 'clam'},
      :session => {:return_to => '/awesome_place'}
    assert_equal 302, status
    assert_equal '/awesome_place', response.headers['Location']
  end

  #test "shows custom login template" do
    #get '/login'
    #assert_match /Custom login/, body
  #end

  test "logs user out" do
    get '/logout', :session => {:current_user => true}
    follow!
    assert_equal 302, status
    assert_equal '/login', response.headers['Location']
  end
end
