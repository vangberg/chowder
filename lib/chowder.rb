require 'sinatra/base'
require 'ostruct'
require 'openid'
require 'openid/store/filesystem'

module Chowder
  class Base < Sinatra::Base
    LOGIN_VIEW = <<-HTML
      <form action="/login" method="POST">
        Login: <input type="text" name="login" /><br />
        Password: <input type="password" name="password" /><br />
        <input type="submit" value="Login" />
      </form>
      OpenID:
      <form action="/openid/initiate" method="POST">
        URL: <input type="text" name="openid_identifier" /><br />
        <input type="submit" value="Login" />
      </form>
    HTML

    # Override this until in Sinatra supports it. See
    # http://sinatra.lighthouseapp.com/projects/9779/tickets/160
    def initialize(app=nil, *args, &block)
      @app = app
      @middleware = OpenStruct.new(:args => args, :block => block)
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
      login, password = params[:login], params[:password]
      if session[:current_user] = @middleware.block.call(login, password)
        redirect(session[:redirect_to] || '/')
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
      if res.is_a?(::OpenID::Consumer::SuccessResponse)
        if session[:current_user] = @middleware.block.call(res.identity_url)
          redirect(session[:redirect_to] || '/')
        end
      end
      redirect '/login'
    end
  end
end
