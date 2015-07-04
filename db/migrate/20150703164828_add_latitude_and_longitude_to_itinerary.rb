class AddLatitudeAndLongitudeToItinerary < ActiveRecord::Migration
  def change
    add_column :itineraries, :origin_latitude, :float
    add_column :itineraries, :origin_longitude, :float
    add_column :itineraries, :destination_latitude, :float
    add_column :itineraries, :destination_longitude, :float
  end
end
