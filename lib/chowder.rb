require 'sinatra/base'
require 'ostruct'

module Chowder
  class Base < Sinatra::Base
    disable :raise_errors

    LOGIN_VIEW = <<-HTML
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html lang='en-us' xmlns='http://www.w3.org/1999/xhtml'>
      <head><title>Log In</title></head>
      <body>
        <form action="/login" method="post">
          <div id="basic_login_field">
            <label for="login">Login: </label>
            <input id="login" type="text" name="login" /><br />
          </div>
          <div id="basic_password_field">
            <label for="password">Password: </label>
            <input id="password" type="password" name="password" /><br />
          </div>
          <div id="basic_login_button">
            <input type="submit" value="Login" />
          </div>
        </form>
        <p>OpenID:</p>
        <form action="/openid/initiate" method="post">
          <div id="openid_login_field">
            <label for="openid_identifier">URL: </label>
            <input id="openid_identifier" type="text" name="openid_identifier" /><br />
          </div>
          <div id="openid_login_button">
            <input type="submit" value="Login" />
          </div>
        </form>
      </body></html>
    HTML

    SIGNUP_VIEW = <<-HTML
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html lang='en-us' xmlns='http://www.w3.org/1999/xhtml'>
      <head><title>Sign Up</title></head>
      <body>
        __ERRORS__
        <form action="/signup" method="post">
          <div id="basic_login_field">
            <label for="login">Login: </label>
            <input id="login" type="text" name="login" /><br />
          </div>
          <div id="basic_password_field">
            <label for="password">Password: </label>
            <input id="password" type="password" name="password" /><br />
          </div>
          <div id="basic_signup_button">
            <input type="submit" value="Sign Up" />
          </div>
        </form>
      </body></html>
    HTML

    def self.new(app=nil, args={}, &block)
      builder = Rack::Builder.new
      builder.use Rack::Session::Cookie, :secret => args[:secret]
      builder.run super
      builder.to_app
    end

    def initialize(app=nil, args={}, &block)
      @signup_callback = args[:signup]
      @login_callback = args[:login] || block
      super(app)
    end

    def authorize(user)
      session[:current_user] = user
    end

    def return_or_redirect_to(path)
      redirect(session[:return_to] || request.script_name + path)
    end

    def render_custom_template(type)
      views_dir = self.options.views || "./views"
      template = Dir[File.join(views_dir, "#{type}.*")].first
      if template
        engine = File.extname(template)[1..-1]
        send(engine, type)
      end
    end

    get '/login' do
      render_custom_template(:login) || LOGIN_VIEW
    end

    get '/logout' do
      session[:current_user] = nil
      redirect request.script_name + '/'
    end
  end

  class Basic < Base
    post '/login' do
      login, password = params['login'], params['password']
      if authorize @login_callback.call(login, password)
        return_or_redirect_to '/'
      else
        redirect request.script_name + '/login'
      end
    end

    get '/signup' do
      if @signup_callback
        render_custom_template(:signup) || signup_view_with_errors([])
      else
        throw :pass
      end
    end

    post '/signup' do
      throw :pass unless @signup_callback

      # results is either [true, <userid>] or [false, <errors>]
      successful_signup, *extras = @signup_callback.call(params)
      if successful_signup
        authorize extras[0]
        return_or_redirect_to '/'
      else
        @errors = extras
        render_custom_template(:signup) || signup_view_with_errors(extras)
        SIGNUP_VIEW.gsub(
          /__ERRORS__/,
          @errors.map { |e| "<p class=\"error\">#{e}</p>" }.join("\n")
        )
      end
    end

    private
    def signup_view_with_errors(errors)
      SIGNUP_VIEW.gsub(
        /__ERRORS__/,
        errors.map { |e| "<p class=\"error\">#{e}</p>" }.join("\n")
        )
    end
  end
end
