class LabController < ApplicationController
  # A workshop page, not a shop page: the three motion pieces live here while
  # they are being built, and it is deliberately not in the public navigation.
  def show
    authorize Page, :index?
  end
end
