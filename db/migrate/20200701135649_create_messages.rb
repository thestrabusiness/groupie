class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.references :group, index: true, null: false, foreign_key: true

      t.string :user_id, null: false, index: true
      t.boolean :system, null: false, index: true, default: false

      t.string :avatar_url
      t.text :text
      t.text :favorited_by, null: false, array: true, default: []
      t.integer :favorites_count, null: false, default: 0
      t.jsonb :attachments, null: false, default: {}
      t.json :raw_message, null: false, default: {}

      t.timestamps null: false
    end

    add_column :users, :group_ids, :text, null: false, array: true, default: []
    add_column :groups, :messages_last_fetched_at, :datetime
  end
end
