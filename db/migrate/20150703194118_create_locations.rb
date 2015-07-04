class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :type
      t.datetime :time
      t.string :address
      t.string :airport
      t.string :gate
      t.float :latitude
      t.float :longitude

      t.timestamps null: false
    end
  end
end
