class PagesController < ApplicationController
  # The static page allowlist. Routes already constrain the slug to these values
  # (`page_slugs` in config/routes.rb); repeating it here means the render path
  # can never be built from an arbitrary parameter, even if a future route
  # change loosens that.
  STATIC_SLUGS = %w[about license contact privacy terms cookies].freeze

  def show
    @page_slug = params[:slug].to_s
    raise ActiveRecord::RecordNotFound unless STATIC_SLUGS.include?(@page_slug)

    @page = Page.published.find_by(slug: @page_slug)

    # A published database page wins; otherwise the view template is used, so a
    # page can exist before an editor has written it into the database.
    authorize @page || Page.new(slug: @page_slug, status: "published")

    if @page
      render :database_page
    else
      render template: "pages/#{@page_slug}"
    end
  end

  def home
    authorize Page, :index?

    @genres = Genre.published.ordered.limit(6)
    @plans = Plan.active.ordered
    @recent_tracks = Track.published.ordered.limit(6).includes(:genre)
  end
end
