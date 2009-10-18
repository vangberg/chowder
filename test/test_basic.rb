require File.join(File.dirname(__FILE__), 'helpers')

class MyApp < Sinatra::Base
  get '/' do
    redirect '/login' unless session[:current_user]
    "protected area"
  end
end

class TestBasic < Test::Unit::TestCase
  def setup
    Chowder::Basic.set :environment, :test

    @app = Rack::Builder.new {
      use Chowder::Basic do |login, password|
        login == "harry" && password == "clam"
      end
      run MyApp
    }
  end

  def test_shows_login_page
    get '/login'
    assert_match /Login/, body
  end

  def test_redirects_on_authentication_success
    post '/login', :login => 'harry', 'password' => 'clam'
    assert_equal 302, status
    assert_equal '/', response.headers['Location']
  end

  def test_redirects_failed_authentication_attempts_to_login
    post '/login', :login => 'harry', 'password' => 'salad'
    assert_equal 302, status
    assert_equal '/login', response.headers['Location']
  end

  def test_redirects_to_specified_URL_after_login
    post '/login', {:login => 'harry', 'password' => 'clam'},
      :session => {:return_to => '/awesome_place'}
    assert_equal 302, status
    assert_equal '/awesome_place', response.headers['Location']
  end

  def test_allows_authenticated_users
    get '/', {}, :session => {:current_user => "harry"}
    assert_equal "protected area", body
  end

  #test "shows custom login template" do
    #get '/login'
    #assert_match /Custom login/, body
  #end

  def test_logs_user_out
    get '/logout', :session => {:current_user => true}
    follow!
    assert_equal 302, status
    assert_equal '/login', response.headers['Location']
  end
end

