class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :authenticate_user
  before_action :set_default_response_format

  protected

  def authenticate_user
    @current_user = User.find_by_token(request.headers['user_token'])
    unless @current_user
      head :unauthorized
    end
  end

  def set_default_response_format
    request.format = 'json'.to_sym if params[:format].nil?
  end
end
