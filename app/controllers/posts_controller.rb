class PostsController < ApplicationController
  def index
    authorize Post, :index?

    @posts = policy_scope(Post).published.recent
  end

  def show
    @post = Post.find_by!(slug: params[:slug])
    authorize @post
  end
end
