module StructuredDataHelper
  # JSON-LD. The pricing skill's highest-impact, lowest-effort fix: buyers now ask
  # an assistant "what does this cost?" before they ever visit, and a price that
  # exists only inside a styled table is invisible to that assistant. The markup
  # here is the same information a human sees, in a form a machine can quote.
  def structured_data(payload)
    tag.script(payload.to_json.html_safe, type: "application/ld+json")
  end

  def plans_structured_data(plans)
    {
      "@context" => "https://schema.org",
      "@graph" => plans.map { |plan| plan_offer_structured_data(plan) }
    }
  end

  def plan_offer_structured_data(plan)
    {
      "@type" => "Product",
      "name" => "#{plan.name} - AI Pop Music subscription",
      "description" => plan_summary(plan),
      "brand" => { "@type" => "Brand", "name" => "AI Pop Music" },
      "offers" => {
        "@type" => "Offer",
        "url" => plans_url,
        "price" => format("%.2f", plan.price),
        "priceCurrency" => plan.currency,
        "availability" => "https://schema.org/InStock",
        "priceSpecification" => {
          "@type" => "UnitPriceSpecification",
          "price" => format("%.2f", plan.price),
          "priceCurrency" => plan.currency,
          "billingIncrement" => 1,
          "billingDuration" => plan.per_month? ? "P1M" : "P1Y"
        }
      }
    }
  end

  def faq_structured_data(pairs)
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => pairs.map do |question, answer|
        {
          "@type" => "Question",
          "name" => question,
          "acceptedAnswer" => { "@type" => "Answer", "text" => answer }
        }
      end
    }
  end

  # Plain text, because a machine reading this has no idea what a "genre slot" is.
  def plan_summary(plan)
    "#{plan.formatted_price} per #{plan.per_month? ? 'month' : 'year'}. " \
      "Covers #{plan.genre_limit} #{"genre".pluralize(plan.genre_limit)} of the subscriber's choice, " \
      "with unlimited downloads of full-length 48 kHz stereo masters inside them, " \
      "licensed for commercial use."
  end
end
