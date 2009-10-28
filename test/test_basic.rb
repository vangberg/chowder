require File.join(File.dirname(__FILE__), 'helpers')

class MyApp < Sinatra::Base
  get '/' do
    redirect '/login' unless session[:current_user]
    "protected area"
  end

  get '/alternate_path' do
    session[:return_to] = '/alternate_path'
    redirect '/login' unless session[:current_user]
    "alternate protected area"
  end
end

module ChowderTest
  attr_accessor :app
end

class TestBasic < Test::Unit::TestCase
  include ChowderTest
  def setup
    Chowder::Basic.set :environment, :test

    @app = Rack::Builder.new {
      use Chowder::Basic, :secret => 'shhhh' do |login, password|
        login == "harry" && password == "clam"
      end
      run MyApp
    }
  end

  def login!
    post '/login', :login => 'harry', :password => 'clam'
  end

  def test_shows_login_page
    get '/login'
    assert_match /Login/, last_response.body
  end

  def test_redirects_on_authentication_success
    login!
    assert_equal 302, last_response.status
    assert_equal '/', last_response.headers['Location']
  end

  def test_redirects_failed_authentication_attempts_to_login
    post '/login', :login => 'harry', 'password' => 'salad'
    assert_equal 302, last_response.status
    assert_equal '/login', last_response.headers['Location']
  end

  def test_redirects_to_specified_URL_after_login
    get '/alternate_path'
    login!
    assert_equal 302, last_response.status
    assert_equal '/alternate_path', last_response.headers['Location']
  end

  def test_allows_authenticated_users
    login!
    get '/', {}
    assert_equal "protected area", last_response.body
  end

  def test_logs_user_out
    get '/logout', "rack.session" => {:current_user => true}
    assert_equal 302, last_response.status
    get last_response.headers['Location']
    assert_equal 302, last_response.status
    assert_equal '/login', last_response.headers['Location']
  end
end

class TestCustomHamlLoginForm < Test::Unit::TestCase
  include ChowderTest

  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'test_haml_views')

    @app = Rack::Builder.new {
      use Chowder::Basic do |login, password|
        true
      end
      run MyApp
    }
  end

  begin
    require 'haml'
    def test_haml_login_form
      get '/login'
      assert_match /Custom HAML Login Form/i, last_response.body
      # proof that it got evaluated as haml, not just returned verbatim
      assert_match /4/i, last_response.body
    end
  rescue LoadError
    def test_nothing   # stop the testrunner's moaning about lack of tests
      assert_equal 1, 1
    end
  end
end

class TestCustomErbLoginForm < Test::Unit::TestCase
  include ChowderTest

  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'test_erb_views')

    @app = Rack::Builder.new {
      use Chowder::Basic do |login, password|
        true
      end
      run MyApp
    }
  end

  begin
    require 'erb'
    def test_haml_login_form
      get '/login'
      assert_match /Custom ERB Login Form/i, last_response.body
      # proof that it got evaluated as erb, not just returned verbatim
      assert_match /4/i, last_response.body
    end
  rescue LoadError
    def test_nothing   # stop the testrunner's moaning about lack of tests
      assert_equal 1, 1
    end
  end
end

