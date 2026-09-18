module ApplicationHelper
  # Navigation links styled from one place, so a new nav item cannot silently
  # drift from the rest.
  def nav_link(label, path)
    active = current_page?(path)

    link_to label, path,
      class: [
        "px-3 py-2 text-sm rounded-control transition-colors",
        active ? "text-ink-950 font-medium" : "text-ink-600 hover:text-ink-950"
      ].join(" "),
      aria: (active ? { current: "page" } : nil)
  end

  def page_title(title)
    content_for(:title) { "#{title} · AI Pop Music" }
  end

  def page_description(description)
    content_for(:description) { description }
  end

  # Status is never colour alone: the chip carries the word too.
  def status_chip(text, tone: :muted)
    tag.span text.titleize, class: "chip chip-#{tone}"
  end

  def formatted_price(cents, currency = "USD")
    symbol = currency == "USD" ? "$" : "#{currency} "
    format("%s%g", symbol, BigDecimal(cents) / 100)
  end
end
