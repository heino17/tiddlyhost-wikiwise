# app/controllers/site_votes_controller.rb

class SiteVotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site

  def create
    @vote = @site.site_votes.find_or_initialize_by(user: current_user)

    submitted_value = params.dig(:site_vote, :value)

    if submitted_value.blank?
      # Bewertung entfernen
      @vote.destroy if @vote.persisted?
      flash_message = t('votes.removed')
      flash_type = "info"  # oder "warning"
    else
      # Bewertung setzen oder ändern
      @vote.value = submitted_value.to_i
      @vote.save!
      flash_message = t('votes.saved')
      flash_type = "success"
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          # 1. Den gesamten Vote-Bereich aktualisieren (Sterne, Durchschnitt, Text)
          turbo_stream.replace(
            "site_vote_#{@site.id}",
            partial: "sites/vote_partial",   # ← oder "site_votes/vote_partial" – je nachdem wo dein Partial liegt
            locals: { site: @site }
          ),

          # 2. Flash-Nachricht **direkt über** dem Vote-Bereich einfügen
          turbo_stream.prepend(
            "site_vote_#{@site.id}",
            "<div class='alert alert-#{flash_type} alert-dismissible fade show mb-2'>#{flash_message}<button type='button' class='btn-close' data-bs-dismiss='alert'></button></div>".html_safe
          )
        ]
      end

      # Fallback für Nicht-Turbo-Clients (z. B. JS deaktiviert)
      format.html do
        redirect_back fallback_location: hub_path,
                      notice: flash_message,
                      status: :see_other
      end
    end
  end

  # Falls du eine separate update-Action hast:
  def update
    create   # gleiche Logik wie create
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end
end