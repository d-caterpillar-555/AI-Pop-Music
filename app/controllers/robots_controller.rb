class RobotsController < ApplicationController
  def show
    authorize Page, :index?

    respond_to do |format|
      format.text
    end
  end
end
