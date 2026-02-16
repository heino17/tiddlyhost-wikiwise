module SiteVotesHelper
  def star_rating(score, max: 5)
    return content_tag(:span, "–", class: "text-muted") if score.nil? || score.zero?

    # BigDecimal → Float umwandeln (genug für Sterne)
    score_f = score.to_f

    content_tag :span, class: 'd-flex align-items-center gap-1' do
      (1..max).map do |i|
        if i <= score_f.floor
          content_tag :span, '★', style: 'color: #f59e0b; font-size: 1.1em;'
        elsif i == score_f.ceil && score_f != score_f.floor
          content_tag :span, '★', style: 'color: #f59e0b; opacity: 0.45; font-size: 1.1em;' # halber Stern-Effekt
        else
          content_tag :span, '☆', style: 'color: #d1d5db; font-size: 1.1em;'
        end
      end.join.html_safe
    end
  end

  def flash_class(type)
    case type.to_sym
    when :notice   then "success"
    when :alert    then "danger"
    when :error    then "danger"
    when :warning  then "warning"
    else "info"
    end
  end

end