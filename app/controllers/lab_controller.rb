class LabController < ApplicationController
  # A workshop page, not a shop page: the three motion pieces live here while
  # they are being built, and it is deliberately not in the public navigation.
  def show
    authorize Page, :index?

    # Only tracks whose shape has been captured can be drawn, so the visualiser
    # offers what it can actually render.
    @tracks = Track.published.where.not(peaks: nil).ordered
  end
end
