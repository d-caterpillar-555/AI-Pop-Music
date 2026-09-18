class SitemapsController < ApplicationController
  def show
    authorize Page, :index?

    @genres = Genre.published.ordered
    @tracks = Track.published.ordered
    @posts = Post.published.recent
    @pages = Page.published.ordered

    respond_to do |format|
      format.xml
    end
  end
end
