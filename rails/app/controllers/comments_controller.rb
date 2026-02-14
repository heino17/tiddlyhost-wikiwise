class CommentsController < ApplicationController
  before_action :authenticate_user!  # falls Devise oder ähnliches benutzt wird
  before_action :set_site

  def index
    @comments = @site.comments.includes(:user).order(created_at: :desc)
    # Optional: .page(params[:page]).per(25) wenn du Pagination willst
  end

  def create
    @comment = @site.comments.find_or_initialize_by(user: current_user)
    @comment.body = comment_params[:body]

    if @comment.new_record?
      success_message = t('comments.created')
    else
      @comment.edited_at = Time.current
      success_message = t('comments.updated')
    end

    respond_to do |format|
      if @comment.save
        format.turbo_stream do
          render turbo_stream: [
            # 1. Den gesamten Kommentar-Bereich aktualisieren
            turbo_stream.replace(
              "site_comments_#{@site.id}",
              partial: "sites/comment_section",
              locals: { site: @site }
            ),

            # 2. Flash-Nachricht direkt oben einfügen
            turbo_stream.prepend(
              "site_comments_#{@site.id}",
              "<div class='alert alert-success alert-dismissible fade show alert-flash mb-2' role='alert' style='font-size: 65%;'>
                 #{success_message}
                 <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
               </div>".html_safe
            )
          ]
        end

        format.html do
          redirect_back fallback_location: site_path(@site),
                        notice: success_message,
                        status: :see_other
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "comment_form_errors_#{@site.id}",
            partial: "shared/form_errors",
            locals: { object: @comment }
          )
        end

        format.html do
          redirect_back fallback_location: site_path(@site),
                        alert: @comment.errors.full_messages.to_sentence
        end
      end
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
  
    # Authorization
    return head :forbidden unless @comment.user == current_user || user_is_admin?

    site = @comment.site   # merken, bevor wir löschen
    @comment.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          # Kommentar direkt aus dem DOM entfernen (live)
          turbo_stream.remove("comment_#{@comment.id}"),

          # Optional: gesamten Bereich neu rendern (wenn du Count aktualisieren willst)
          turbo_stream.replace(
            "site_comments_#{@comment.site.id}",
            partial: "sites/comment_section",
            locals: { site: @comment.site }
          ),

         # Flash-Nachricht oben einfügen
          turbo_stream.prepend(
            "site_comments_#{@comment.site.id}",
            "<div class='alert alert-success alert-dismissible fade show alert-flash mb-2' role='alert' style='font-size: 65%;'>
               #{t('comments.deleted')}
               <button type='button' class='btn-close' data-bs-dismiss='alert'></button>
             </div>".html_safe
          )
        ]
      end

      format.html do
        redirect_back fallback_location: site_path(@comment.site),
                      notice: t('comments.deleted'),
                      status: :see_other
      end
    end
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
