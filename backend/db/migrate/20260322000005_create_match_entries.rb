class CreateMatchEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :match_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.references :captain, null: true, foreign_key: { to_table: :ipl_players }
      t.references :vice_captain, null: true, foreign_key: { to_table: :ipl_players }
      t.decimal :total_points, precision: 10, scale: 2, default: 0
      t.timestamps
    end

    add_index :match_entries, [:user_id, :match_id], unique: true
  end
end
