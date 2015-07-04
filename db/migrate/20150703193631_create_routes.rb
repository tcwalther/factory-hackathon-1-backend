class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :price_cents
      t.string :currency

      t.timestamps null: false
    end
  end
end
