class AddSenderNameToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :sender_name, :string

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE messages SET sender_name = raw_message ->> 'name'
        SQL
      end
    end

    change_column_null :messages, :sender_name, false
  end
end
