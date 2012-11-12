module ApplicationHelper

  # Mixin for generating a span with an icon
  def icon_mixin(type, content)
    "<span><i class='icon-#{ type }'></i> #{ content }</span>".html_safe
  end

end
