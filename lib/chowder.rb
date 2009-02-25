require 'sinatra/base'

class Chowder < Sinatra::Base
  helpers do
    def find_login_template
      views_dir = self.options.views || "./views"
      template = Dir[File.join(views_dir, 'login.*')].first
    end
  end

  get '/login' do
    if template = find_login_template
      engine = File.extname(template)[1..-1]
      # Resort to this dirty hack. Haml/erb are required by haml()/erb() and
      # thus calling render() without requiring haml/erb will result in error
      # and this is just shorter bla bla bla
      send(engine, :login)
    else
      <<-HTML
      <form action="/login" method="POST">
        Login: <input type="text" name="login" /><br />
        Password: <input type="password" name="password" /><br />
        <input type="submit" value="Login" />
      </form>
      HTML
    end
  end

  post '/login' do
    login, password = params[:login], params[:password]
    if session[:current_user] = @middleware.block.call(login, password)
      redirect(session[:redirect_to] || '/')
    else
      redirect '/login'
    end
  end

  get '/logout' do
    session[:current_user] = nil
    redirect '/'
  end
end
