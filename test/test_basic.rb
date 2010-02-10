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

  get "/userid" do
    session[:return_to] = '/userid'
    redirect '/login' unless session[:current_user]
    session[:current_user].to_s
  end

  get '/*' do
    "fallback"
  end

  post '/*' do
    "fallback post"
  end
end

module ChowderTest
  attr_accessor :app
end

class TestBasic < Test::Unit::TestCase
  include ChowderTest
  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'nowhere')

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

class TestBasicRelative < Test::Unit::TestCase
  include ChowderTest
  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'nowhere')

    @app = Rack::Builder.new {
      map "/foo" do
        use Chowder::Basic, :secret => 'shhhh' do |login, password|
          login == "harry" && password == "clam"
        end
        run MyApp
      end
    }
  end

  def login!
    post '/foo/login', :login => 'harry', :password => 'clam'
  end

  def test_redirects_on_authentication_success
    login!
    assert_equal 302, last_response.status
    assert_equal '/foo/', last_response.headers['Location']
  end

  def test_redirects_failed_authentication_attempts_to_login
    post '/foo/login', :login => 'harry', 'password' => 'salad'
    assert_equal 302, last_response.status
    assert_equal '/foo/login', last_response.headers['Location']
  end
end

class TestSpecifyingLoginCallbackInHash < Test::Unit::TestCase # blurgh, what a name
  include ChowderTest

  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'nowhere')

    @app = Rack::Builder.new {
      use Chowder::Basic,
      :secret => 'shhhh',
      :login => proc { |login, password|
        login == "harry" && password == "clam"
      }

      run MyApp
    }
  end

  def test_logging_in
    post '/login', :login => 'harry', :password => 'clam'
    get '/'
    assert_equal "protected area", last_response.body
  end
end

class TestSignup < Test::Unit::TestCase
  include ChowderTest

  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'nowhere')

    @app = Rack::Builder.new {
      use Chowder::Basic, {
        :signup => lambda { |params|
          if params[:login].length < 8
            [true, params[:login]]
          else
            [false, "It's too long", "(that's what she said)"]
          end
        },
      } do |l, p|
        true
      end
      run MyApp
    }
  end

  def test_signup_route
    get '/signup'
    assert_match /Sign Up/, last_response.body
  end

  def test_successful_signup
    post '/signup', {'login' => 'alice', 'password' => 'abc123'}
    assert_equal '/', last_response.headers["Location"]

    get '/userid'
    assert_equal 'alice', last_response.body
  end

  def test_unsuccessful_signup
    post '/signup', {'login' => 'usernameistoolong', 'password' => 'abc123'}
    assert_match(/too long/, last_response.body)
    assert_match(/that\'s what she said/, last_response.body)
  end
end

class TestNoSignup < Test::Unit::TestCase
  include ChowderTest

  Chowder::Basic.set :environment, :test
  Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'nowhere')

  def setup
    @app = Rack::Builder.new {
      use Chowder::Basic do |login, password|
        true
      end
      run MyApp
    }
  end

  def test_get_signup_is_skipped
    get '/signup'
    assert_equal 'fallback', last_response.body
  end

  def test_post_signup_is_skipped
    post '/signup', :login => 'argyle', :password => 'sock'
    assert_equal 'fallback post', last_response.body
  end
end

class TestCustomHamlViews < Test::Unit::TestCase
  include ChowderTest

  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'test_haml_views')

    @app = Rack::Builder.new {
      use Chowder::Basic, {
        :signup => lambda { |params| 1 }
      } do |login, password|
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

    def test_haml_signup_form
      get '/signup'
      assert_match /Custom HAML Signup Form/i, last_response.body
      # proof that it got evaluated as haml, not just returned verbatim
      assert_match /5/i, last_response.body
    end
  rescue LoadError
    def test_nothing   # stop the testrunner's moaning about lack of tests
      assert_equal 1, 1
    end
  end
end

class TestCustomErbViews < Test::Unit::TestCase
  include ChowderTest

  def setup
    Chowder::Basic.set :environment, :test
    Chowder::Basic.set :views, File.join(File.dirname(__FILE__), 'test_erb_views')

    @app = Rack::Builder.new {
      use Chowder::Basic, {
        :signup => lambda { |params| 1 }
      } do |login, password|
        true
      end
      run MyApp
    }
  end

  begin
    require 'erb'
    def test_erb_login_form
      get '/login'
      assert_match /Custom ERB Login Form/i, last_response.body
      # proof that it got evaluated as erb, not just returned verbatim
      assert_match /4/i, last_response.body
    end

    def test_erb_signup_form
      get '/signup'
      assert_match /Custom ERB Signup Form/i, last_response.body
      # proof that it got evaluated as erb, not just returned verbatim
      assert_match /5/i, last_response.body
    end
  rescue LoadError
    def test_nothing   # stop the testrunner's moaning about lack of tests
      assert_equal 1, 1
    end
  end
end
