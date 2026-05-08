class SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  private

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:redir_to_site])
  end

  def after_sign_in_path_for(resource)
    # 1. Admin-Weiterleitung
    if resource.is_superuser?
      return admin_path
    end
  
    # 2. Deine bestehende private-site-Weiterleitung
    if request.post? && params[:user] &&
       (@site_redir = params[:user][:site_redir]) &&
       (@site = Site.find_by_name(@site_redir)) &&
       @site.user == current_user
      return @site.url
    end

    # 3. Standard-Devise-Weiterleitung
    super
  end
end
