class TeamSelection < ApplicationRecord
  belongs_to :match_entry
  belongs_to :ipl_player

  validates :ipl_player_id, uniqueness: { scope: :match_entry_id }
end
