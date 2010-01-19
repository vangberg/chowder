module Chowder
  module Rails
    def current_user
      session[:current_user]
    end

    def authorized?
      session[:current_user]
    end

    def login
      session[:redirect_to] = request.path_info
      redirect_to '/login'
    end

    def logout
      session[:current_user] = nil
    end

    def require_user
      login unless authorized?
    end
  end
end
