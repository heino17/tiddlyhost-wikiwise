class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show_admin, :edit_admin, :update_admin, :destroy_admin]
  before_action :require_admin!, only: [
    :new_admin, :create_admin, :show_admin, :edit_admin,
    :update_admin, :destroy_admin
  ]

  def user_params_admin
    params.require(:user).permit(
      :name,
      :email,
      :username,
      :user_type_id,
      :password,
      :password_confirmation
    )
  end

  def edit_admin
    render "admin/edit_user"
  end

  def update_admin
    @user = User.find(params[:id])
    @user.skip_password_validation = true
  
    if @user.update(user_params_admin)
      redirect_to admin_user_path(@user), notice: t("admin.tab_users.users_edit_user_account_flash_updated")
    else
      render "admin/edit_user", status: :unprocessable_entity
    end
  end

  def new_admin
    @user = User.new
    render 'admin/new_user'
  end

  def create_admin
    @user = User.new(user_params_admin)
    @user.skip_password_validation = true
  
    # User sofort bestätigen
    @user.confirmed_at = Time.current
    @user.confirmation_token = nil
    @user.confirmation_sent_at = nil
  
    if @user.save
      redirect_to admin_user_path(@user), notice: t("admin.tab_users.users_edit_user_account_flash_created")
    else
      render "admin/new_user", status: :unprocessable_entity
    end
  end

  def show_admin
    render 'admin/show_user'
  end

  def destroy_admin
    if @user == current_user
      redirect_to admin_user_path(@user), alert: t("admin.tab_users.users_edit_user_account_flash_dont_delete_yourself")
      return
    end
  
    @user.destroy
    redirect_to admin_users_path, notice: t("admin.tab_users.users_edit_user_account_flash_deleted")
  end

  private

  def require_admin!
    unless current_user&.is_admin?
      redirect_to root_path, alert: t("admin.tab_users.users_edit_user_account_flash_no_permission")
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :username,
      :password, :password_confirmation
    )
  end
end
