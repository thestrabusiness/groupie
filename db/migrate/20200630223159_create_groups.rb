class CreateGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :groups do |t|
      t.timestamps null: false
      t.string :name, null: false
      t.string :image_url
    end
  end
end
