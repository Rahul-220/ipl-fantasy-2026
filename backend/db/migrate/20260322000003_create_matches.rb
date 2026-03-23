class CreateMatches < ActiveRecord::Migration[7.2]
  def change
    create_table :matches do |t|
      t.references :team1, null: false, foreign_key: { to_table: :ipl_teams }
      t.references :team2, null: false, foreign_key: { to_table: :ipl_teams }
      t.datetime :match_date, null: false
      t.string :venue
      t.string :status, null: false, default: "upcoming" # upcoming, live, completed
      t.integer :match_number
      t.string :api_match_id
      t.timestamps
    end
  end
end
