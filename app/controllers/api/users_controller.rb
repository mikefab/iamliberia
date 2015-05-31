class Api::UsersController < ApplicationController
  respond_to :json

  def index
    render json: User.all.map(&:username)
  end
end