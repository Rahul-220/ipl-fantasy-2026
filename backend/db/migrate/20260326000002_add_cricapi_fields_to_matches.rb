class AddCricapiFieldsToMatches < ActiveRecord::Migration[7.2]
  def change
    add_column :matches, :cricapi_match_id, :string
    add_column :matches, :last_synced_at, :datetime
    add_column :matches, :auto_sync, :boolean, default: false
    add_index :matches, :cricapi_match_id
  end
end
