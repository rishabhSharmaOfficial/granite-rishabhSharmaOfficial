# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    users = User.select(:id, :name)
    render status: :ok, json: { users: users }
  end

  def create
    user = User.new(user_params)
    user.save!
    respond_with_success(t("successfully_created", entity: "User"))
    # respond_with_success("User was successfully created!")
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
