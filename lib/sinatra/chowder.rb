require 'sinatra/base'

module Sinatra
  module Chowder
    def current_user
      session[:current_user]
    end

    def authorized?
      session[:current_user]
    end

    def login
      session[:redirect_to] = request.path_info
      redirect request.script_name + '/login'
    end

    def logout
      session[:current_user] = nil
    end

    def require_user
      login unless authorized?
    end
  end

  helpers Chowder
end
