require "nokogiri"
require "net/http"
require "json"

class CricbuzzScraper
  BASE_URL = "https://www.cricbuzz.com"

  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept" => "text/html,application/xhtml+xml",
    "Accept-Language" => "en-US,en;q=0.9"
  }.freeze

  TEAM_ALIASES = {
    "rcb" => ["royal challengers", "bengaluru", "bangalore"],
    "csk" => ["chennai", "super kings"],
    "mi"  => ["mumbai", "indians"],
    "kkr" => ["kolkata", "knight riders"],
    "dc"  => ["delhi", "capitals"],
    "rr"  => ["rajasthan", "royals"],
    "srh" => ["sunrisers", "hyderabad"],
    "pbks" => ["punjab", "kings"],
    "gt"  => ["gujarat", "titans"],
    "lsg" => ["lucknow", "super giants"],
  }.freeze

  # ─── Discover live IPL matches ───────────────────────────
  def self.fetch_live_ipl_matches
    url = "#{BASE_URL}/cricket-match/live-scores"
    html = fetch_html(url)
    return [] unless html

    doc = Nokogiri::HTML(html)
    matches = []

    doc.css("a[href*='/live-cricket-scores/']").each do |link|
      href = link["href"].to_s
      text = link.text.strip.downcase

      next unless href =~ /\/live-cricket-scores\/(\d+)\//
      match_id = $1

      # Only IPL matches
      next unless text.include?("ipl") || text.include?("premier league") ||
                  href.include?("indian-premier-league") || href.include?("ipl-")

      # Extract team abbreviations from the slug
      if href =~ /\/(\w+)-vs-(\w+)-/
        matches << {
          cricbuzz_id: match_id,
          team1: $1.upcase,
          team2: $2.upcase,
          title: link.text.strip
        }
      end
    end

    matches.uniq { |m| m[:cricbuzz_id] }
  end

  # ─── Get live match status (server-rendered, lightweight) ───
  def self.fetch_match_status(cricbuzz_match_id)
    url = "#{BASE_URL}/live-cricket-scores/#{cricbuzz_match_id}"
    html = fetch_html(url)
    return nil unless html

    doc = Nokogiri::HTML(html)

    completed = doc.css(".cb-col.cb-col-100.cb-min-stts.cb-text-complete").text.strip
    innings_break = doc.css(".cb-text-inningsbreak").text.strip
    in_progress = doc.css(".cb-text-inprogress").text.strip

    match_state = if completed.present? && (completed.downcase.include?("won") || completed.downcase.include?("tied") || completed.downcase.include?("no result"))
                    "completed"
                  elsif innings_break.present?
                    "innings_break"
                  elsif in_progress.present?
                    "live"
                  else
                    "unknown"
                  end

    {
      match_state: match_state,
      status_text: completed.presence || innings_break.presence || in_progress.presence || "unknown",
      cricbuzz_id: cricbuzz_match_id
    }
  end

  # ─── Fetch FULL scorecard from embedded Next.js JSON ─────
  # The scorecard page embeds scorecardApiData in RSC payload.
  # No JS execution needed — pure HTTP GET + regex extract.
  def self.fetch_scorecard(cricbuzz_match_id)
    url = "#{BASE_URL}/live-cricket-scorecard/#{cricbuzz_match_id}"
    html = fetch_html(url)
    return nil unless html

    # Extract scorecardApiData from Next.js RSC payload
    scorecard_json = extract_scorecard_json(html)
    return nil unless scorecard_json

    scorecard_json
  end

  # ─── Auto-discover and map Cricbuzz IDs to our matches ───
  def self.auto_map_matches!
    log = []
    discovered = fetch_live_ipl_matches
    log << "🔍 Found #{discovered.size} IPL matches on Cricbuzz"

    discovered.each do |cb|
      team1 = find_team_by_alias(cb[:team1])
      team2 = find_team_by_alias(cb[:team2])
      next unless team1 && team2

      match = Match.where(
        "(team1_id = ? AND team2_id = ?) OR (team1_id = ? AND team2_id = ?)",
        team1.id, team2.id, team2.id, team1.id
      ).where(cricapi_match_id: [nil, ""]).first

      if match
        match.update!(cricapi_match_id: cb[:cricbuzz_id], auto_sync: true)
        log << "✅ Mapped #{cb[:team1]} vs #{cb[:team2]} → ID #{cb[:cricbuzz_id]}"
      end
    end

    log
  end

  private

  def self.fetch_html(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri.request_uri)
    HEADERS.each { |k, v| request[k] = v }

    response = http.request(request)
    return response.body if response.code.to_i == 200

    Rails.logger.warn("[CricbuzzScraper] HTTP #{response.code} for #{url}")
    nil
  rescue => e
    Rails.logger.error("[CricbuzzScraper] Error: #{e.message}")
    nil
  end

  def self.extract_scorecard_json(html)
    # Cricbuzz uses Next.js RSC — scorecard data is in self.__next_f.push payloads
    payloads = html.scan(/self\.__next_f\.push\(\[1,"(.*?)"\]\)/)

    payloads.each do |match|
      payload = match[0]
      next unless payload.include?("scorecardApiData")

      # Unescape the double-escaped JSON
      unescaped = payload.gsub('\\"', '"').gsub('\\\\', '\\')

      # Extract the scorecardApiData object
      idx = unescaped.index('"scorecardApiData"')
      next unless idx

      # Find the opening brace of the value
      start = unescaped.index("{", idx + 18)
      next unless start

      # Use brace counting to find the matching closing brace
      depth = 0
      pos = start
      while pos < unescaped.length
        if unescaped[pos] == "{"
          depth += 1
        elsif unescaped[pos] == "}"
          depth -= 1
          if depth == 0
            json_str = unescaped[start..pos]
            return JSON.parse(json_str)
          end
        end
        pos += 1
      end
    end

    nil
  rescue JSON::ParserError => e
    Rails.logger.error("[CricbuzzScraper] JSON parse error: #{e.message}")
    nil
  end

  def self.find_team_by_alias(short_name)
    # Direct match first
    team = IplTeam.find_by("LOWER(short_name) = ?", short_name.downcase)
    return team if team

    # Try aliases
    TEAM_ALIASES.each do |abbr, names|
      if names.any? { |n| short_name.downcase.include?(n) }
        return IplTeam.find_by("LOWER(short_name) = ?", abbr)
      end
    end

    nil
  end
end
