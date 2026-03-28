class CricApiService
  BASE_URL = "https://api.cricapi.com/v1"

  def initialize
    @api_key = ENV.fetch("CRICAPI_KEY", nil)
  end

  def api_key_present?
    @api_key.present?
  end

  # Fetch current/recent matches — used to discover CricAPI match IDs
  def current_matches(offset: 0)
    get("/currentMatches", offset: offset)
  end

  # Fetch full scorecard for a specific match
  def match_scorecard(cricapi_match_id)
    get("/match_scorecard", id: cricapi_match_id)
  end

  # Fetch match info (lighter than scorecard)
  def match_info(cricapi_match_id)
    get("/match_info", id: cricapi_match_id)
  end

  # Search current matches for an IPL match by team names
  def find_ipl_match(team1_short_name, team2_short_name)
    result = current_matches
    return nil unless result && result["status"] == "success"

    team_aliases = build_team_aliases

    matches = result["data"] || []
    matches.find do |m|
      teams = (m["teams"] || []).map(&:downcase)
      t1_matches = teams.any? { |t| team_matches?(t, team1_short_name, team_aliases) }
      t2_matches = teams.any? { |t| team_matches?(t, team2_short_name, team_aliases) }
      t1_matches && t2_matches
    end
  end

  private

  def get(endpoint, params = {})
    return nil unless api_key_present?

    url = "#{BASE_URL}#{endpoint}"
    params[:apikey] = @api_key

    response = HTTParty.get(url, query: params, timeout: 15)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("[CricAPI] Error: #{e.message}")
    nil
  end

  def team_matches?(api_team_name, short_name, aliases)
    short_lower = short_name.downcase
    full_names = aliases[short_lower] || [short_lower]
    full_names.any? { |name| api_team_name.include?(name) }
  end

  def build_team_aliases
    {
      "rcb" => ["royal challengers", "bengaluru", "bangalore", "rcb"],
      "csk" => ["chennai", "super kings", "csk"],
      "mi"  => ["mumbai", "indians", "mi"],
      "kkr" => ["kolkata", "knight riders", "kkr"],
      "dc"  => ["delhi", "capitals", "dc"],
      "rr"  => ["rajasthan", "royals", "rr"],
      "srh" => ["sunrisers", "hyderabad", "srh"],
      "pbks" => ["punjab", "kings", "pbks"],
      "gt"  => ["gujarat", "titans", "gt"],
      "lsg" => ["lucknow", "super giants", "lsg"],
    }
  end
end
