require 'sinatra/base'
require 'ostruct'
require 'openid'
require 'openid/store/filesystem'

module Chowder
  class Base < Sinatra::Base
    enable :sessions

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

    # Override this until in Sinatra supports it. See
    # http://sinatra.lighthouseapp.com/projects/9779/tickets/160
    def initialize(app=nil, *args, &block)
      @app = app
      @middleware = OpenStruct.new(:args => args, :block => block)
    end

    def authorize(user)
      session[:current_user] = user
    end

    def return_or_redirect_to(path)
      redirect(session[:return_to] || path)
    end

    def find_login_template
      views_dir = self.options.views || "./views"
      template = Dir[File.join(views_dir, 'login.*')].first
    end

    get '/login' do
      if template = find_login_template
        engine = File.extname(template)[1..-1]
        send(engine, :login)
      else
        LOGIN_VIEW
      end
    end

    get '/logout' do
      session[:current_user] = nil
      redirect '/'
    end
  end

  class Basic < Base
    post '/login' do
      login, password = params['login'], params['password']
      if authorize @middleware.block.call(login, password)
        return_or_redirect_to '/'
      else
        redirect '/login'
      end
    end
  end

  class OpenID < Base
    def host
      host = env['HTTP_HOST'] || "#{env['SERVER_NAME']}:#{env['SERVER_PORT']}"
      "http://#{host}"
    end

    def setup_consumer
      store = ::OpenID::Store::Filesystem.new('.openid')
      osession = session[:openid] ||= {}
      @consumer = ::OpenID::Consumer.new(osession, store)
    end

    post '/openid/initiate' do
      setup_consumer
      url = @consumer.begin(params['openid_identifier']).redirect_url(host, host + '/openid/authenticate')
      redirect url
    end

    get '/openid/authenticate' do
      setup_consumer
      res = @consumer.complete(request.params, host + '/openid/authenticate')
      user = @middleware.block.call(res.identity_url)
      if res.is_a?(::OpenID::Consumer::SuccessResponse) && authorize(user)
        return_or_redirect_to '/'
      end
      redirect '/login'
    end
  end
end
