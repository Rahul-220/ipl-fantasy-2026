class CreateTeamSelections < ActiveRecord::Migration[7.2]
  def change
    create_table :team_selections do |t|
      t.references :match_entry, null: false, foreign_key: true
      t.references :ipl_player, null: false, foreign_key: true
      t.timestamps
    end

    add_index :team_selections, [:match_entry_id, :ipl_player_id], unique: true
  end
end
