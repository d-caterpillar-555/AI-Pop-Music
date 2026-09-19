class AddPeaksToTracks < ActiveRecord::Migration[8.1]
  # The stored shape of a track's audio: an array of RMS buckets, computed once
  # and drawn by the visualiser without the browser downloading the song first.
  #
  # Nullable on purpose. A track with no audio has no shape, and inventing one
  # would be a drawing of nothing in particular.
  def change
    add_column :tracks, :peaks, :jsonb
  end
end
