class CreateMessageCache < ActiveRecord::Migration[6.0]
  def change
    create_table :message_caches do |t|
      t.timestamp :started_at, null: false, default: -> { 'now()' }
      t.timestamp :ended_at
      t.references :group, null: false, index: true, foreign_key: true
      t.references :started_by, null: false, index: true,
                                foreign_key: { to_table: 'users' }
    end

    remove_column :groups, :messages_last_fetched_at, :datetime
  end
end
