class CreateIplPlayers < ActiveRecord::Migration[7.2]
  def change
    create_table :ipl_players do |t|
      t.string :name, null: false
      t.references :ipl_team, null: false, foreign_key: true
      t.string :role, null: false # batsman, bowler, all_rounder, wicket_keeper
      t.timestamps
    end
  end
end
