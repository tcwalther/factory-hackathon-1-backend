class CreateItineraries < ActiveRecord::Migration
  def change
    create_table :itineraries do |t|
      t.string :origin_address
      t.string :destination_address
      t.string :departure_airport
      t.string :arrival_airport
      t.string :flight_number

      t.timestamps null: false
    end
  end
end
