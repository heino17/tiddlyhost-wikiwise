class SiteVotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site

  def create
    @vote = @site.site_votes.find_or_initialize_by(user: current_user)

    submitted_value = params.dig(:site_vote, :value)

    if submitted_value.blank?
      @vote.destroy if @vote.persisted?
      flash.now[:notice] = t('votes.removed')
    else
      @vote.value = submitted_value.to_i
      @vote.save!
      flash.now[:notice] = t('votes.saved')
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "site_vote_#{@site.id}",
            partial: "sites/vote_partial",
            locals: { site: @site }
          ),
          turbo_stream.replace(
            "flash_messages",
            partial: "shared/flash"
          )
        ]
      end

      format.html do
        redirect_back fallback_location: hub_path, notice: flash[:notice]
      end

      format.any { head :not_acceptable }
    end

  end

  def update
    create   # gleiche Logik wie create
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end
end