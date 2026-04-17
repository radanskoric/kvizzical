class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = build_user
  end

  def create
    @user = registration_user
    @user.assign_attributes(registration_params)

    if @user.save
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Welcome to Kvizzical!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def build_user
      registration_user.tap do |user|
        user.email_address ||= params[:email_address]
        user.name ||= anonymous_user&.name
      end
    end

    def registration_user
      @registration_user ||= if anonymous_user && anonymous_user.email_address.blank? && anonymous_user.password_digest.blank?
        anonymous_user
      else
        User.new
      end
    end

    def registration_params
      params.expect(user: %i[ name email_address password password_confirmation ])
    end
end
