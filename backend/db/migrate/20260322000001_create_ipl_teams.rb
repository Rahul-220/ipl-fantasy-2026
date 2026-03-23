class CreateIplTeams < ActiveRecord::Migration[7.2]
  def change
    create_table :ipl_teams do |t|
      t.string :name, null: false
      t.string :short_name, null: false
      t.string :logo_url
      t.timestamps
    end
  end
end
