require 'sinatra/base'

class Chowder < Sinatra::Base
  get '/login' do
    erb :login
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

  template :login do
    <<-HTML
    <form action="/login" method="POST">
      Login: <input type="text" name="login" /><br />
      Password: <input type="password" name="password" /><br />
      <input type="submit" value="Login" />
    </form>
    HTML
  end
end
