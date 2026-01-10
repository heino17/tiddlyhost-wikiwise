class TemplatesController < HubController
  private

  def set_default_title
    @thing_name = 'Template'
    @default_title = t('site_templates_title')
    @explanation_text = t('site_templates_explanation_text').squish
  end
end
