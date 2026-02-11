class CommentsController < ApplicationController
  before_action :authenticate_user!  # falls Devise oder ähnliches benutzt wird
  before_action :set_site

  def index
    @comments = @site.comments.includes(:user).order(created_at: :desc)
    # Optional: .page(params[:page]).per(25) wenn du Pagination willst
  end

  def create
    # Prüfe, ob der User schon einen Kommentar hat
    @comment = @site.comments.find_or_initialize_by(user: current_user)
    @comment.body = comment_params[:body]

    if @comment.new_record?
      # erster Kommentar
      if @comment.save
        redirect_back fallback_location: site_path(@site), notice: t('comments.created')
      else
        redirect_back fallback_location: site_path(@site), alert: @comment.errors.full_messages.to_sentence
      end
    else
      # existiert → Update (Editieren)
      @comment.edited_at = Time.current
      if @comment.save
        redirect_back fallback_location: site_path(@site), notice: t('comments.updated')
      else
        redirect_back fallback_location: site_path(@site), alert: @comment.errors.full_messages.to_sentence
      end
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @site = @comment.site   # oder was immer @site bei dir ist

    return head :forbidden unless @comment.user == current_user|| user_is_admin?

    @comment.destroy

    redirect_back_or_to hub_path, notice: t('comments.deleted'), status: :see_other
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
