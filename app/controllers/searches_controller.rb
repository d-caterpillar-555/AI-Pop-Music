class SearchesController < ApplicationController
  def show
    authorize :search, :show?

    @query = params[:q].to_s.strip.first(100)
    @results = []
    @results = CatalogSearch.call(@query) if @query.present?
  end
end
