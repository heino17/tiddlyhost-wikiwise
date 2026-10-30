# Signing out on a site host.
#
# This is not Devise's sign-out: a collaborator is signed in through the
# session (session[:collab_*]), not through Devise, so there is no Devise
# mapping and no Devise user to end. Keeping this in its own controller
# also keeps Devise's mapping checks out of the way.
class SiteSessionsController < ApplicationController
  # SimpleWiki's sign-out button uses fetch() and cannot send the CSRF token.
  # A forged sign-out only ends the victim's own session, it grants nothing.
  # (The TiddlyWiki banner's GET /?collab_logout is just as unprotected.)
  skip_before_action :verify_authenticity_token, only: [:destroy]

  # SimpleWiki links "sign in" to /login, which is the MultiWikiServer
  # convention. Tiddlyhost signs users in through Devise, so send the browser
  # there. A signed-in user goes straight back to the wiki: on a site host the
  # wiki is the root.
  def new
    return redirect_to root_path if user_signed_in?

    redirect_to new_user_session_path
  end

  # Clear both kinds of session, so the button does what it says whether a
  # collaborator or the signed-in owner pressed it.
  def destroy
    session.delete(:collab_site_id)
    session.delete(:collab_name)
    session.delete(:collab_expires_at)
    sign_out(:user) if user_signed_in?
    head :no_content
  end
end
