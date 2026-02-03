class ExploreController < HubController
  private

  def set_default_title
    @thing_name = 'Site'
    @default_title = t('site_explore_title')
    @explanation_text = t('site_explore_explanation_text').squish
  end
end
