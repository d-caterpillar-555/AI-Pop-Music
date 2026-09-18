class GenresController < ApplicationController
  def index
    authorize Genre, :index?

    @genres = policy_scope(Genre).ordered
  end

  def show
    # Looking the genre up through the policy scope means an unpublished genre
    # is a 404 for a visitor rather than a "not allowed" that confirms it exists.
    @genre = policy_scope(Genre).find_by!(slug: params[:slug])
    authorize @genre

    @tracks = @genre.tracks.published.ordered.includes(:genre, audio_attachment: :blob)
  end
end
