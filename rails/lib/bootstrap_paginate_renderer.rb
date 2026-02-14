# https://stackoverflow.com/questions/44680975/custom-will-paginate-renderer

# require 'will_paginate/view_helpers/action_view'

class BootstrapPaginateRenderer < WillPaginate::ActionView::LinkRenderer
  def container_attributes
    { class: 'pagination' }
  end

  def html_container(html)
    child = tag(:ul, html, container_attributes)
    tag(:nav, child)
  end

  def page_number(page)
    turbo_attr = 'data-turbo="false"'.html_safe  # ← NEU!
    if page == current_page
      "<li class=\"page-item active\" #{turbo_attr}>#{link(page, page, rel: rel_value(page), class: 'page-link')}</li>"
    else
      "<li class=\"page-item\" #{turbo_attr}>#{link(page, page, rel: rel_value(page), class: 'page-link')}</li>"
    end
  end

  def previous_page
    num = @collection.current_page > 1 && (@collection.current_page - 1)
    label = I18n.t('will_paginate.previous_label')
    previous_or_next_page(num, "<span aria-hidden=\"true\">&laquo; #{label}</span>")
  end

  def next_page
    num = @collection.current_page < total_pages && (@collection.current_page + 1)
    label = I18n.t('will_paginate.next_label')
    previous_or_next_page(num, "<span aria-hidden=\"true\">#{label} &raquo;</span>")
  end

  def previous_or_next_page(page, text)
    turbo_attr = 'data-turbo="false"'.html_safe  # ← NEU!
    if page
      "<li class=\"page-item\" #{turbo_attr}>#{link(text, page, class: 'page-link')}</li>"
    else
      "<li class=\"page-item disabled\" #{turbo_attr}>#{link(text, page, class: 'page-link')}</li>"
    end
  end
end

