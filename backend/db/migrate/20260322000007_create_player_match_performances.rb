class CreatePlayerMatchPerformances < ActiveRecord::Migration[7.2]
  def change
    create_table :player_match_performances do |t|
      t.references :match, null: false, foreign_key: true
      t.references :ipl_player, null: false, foreign_key: true

      # Batting
      t.integer :runs_scored, default: 0
      t.integer :balls_faced, default: 0
      t.integer :fours, default: 0
      t.integer :sixes, default: 0
      t.boolean :is_duck, default: false
      t.boolean :did_bat, default: false

      # Bowling
      t.decimal :overs_bowled, precision: 4, scale: 1, default: 0
      t.integer :maidens, default: 0
      t.integer :runs_conceded, default: 0
      t.integer :wickets, default: 0
      t.integer :lbw_bowled_count, default: 0 # count of LBW + Bowled dismissals

      # Fielding
      t.integer :catches, default: 0
      t.integer :stumpings, default: 0
      t.integer :direct_run_outs, default: 0
      t.integer :indirect_run_outs, default: 0

      # Calculated
      t.decimal :fantasy_points, precision: 10, scale: 2, default: 0

      t.timestamps
    end

    add_index :player_match_performances, [:match_id, :ipl_player_id], unique: true, name: "idx_perf_match_player"
  end
end
