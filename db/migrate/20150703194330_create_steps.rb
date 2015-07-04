class CreateSteps < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.references :route, index: true, foreign_key: true
      t.string :type
      t.integer :departure_id
      t.integer :arrival_id

      t.timestamps null: false
    end
  end
end
