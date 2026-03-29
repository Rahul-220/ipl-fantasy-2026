import { useState, useEffect, useContext } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { getMatch, deleteMatchEntry } from '../api';
import { UserContext } from '../App';

function MatchDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { currentUser } = useContext(UserContext);
  const [matchData, setMatchData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [expandedEntry, setExpandedEntry] = useState(null);
  const [expandedPlayer, setExpandedPlayer] = useState(null);

  useEffect(() => {
    loadMatch();
  }, [id]);

  const loadMatch = () => {
    getMatch(id, currentUser?.id).then(res => {
      setMatchData(res.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  };

  if (loading) {
    return <div className="loading-container"><div className="loader"></div><p>Loading match...</p></div>;
  }

  if (!matchData) {
    return <div className="error-state">Match not found</div>;
  }

  const { match, entries, entries_count, is_full } = matchData;
  const userEntry = entries.find(e => e.user?.id === currentUser?.id);
  const userHasEntry = !!userEntry;
  const matchStarted = match.status !== 'upcoming' || new Date(match.match_date) <= new Date();

  const handleWithdraw = async () => {
    if (!window.confirm('Withdraw your team? You can re-pick before the match starts.')) return;
    try {
      await deleteMatchEntry(id, userEntry.id);
      loadMatch();
    } catch (err) {
      alert(err.response?.data?.error || 'Error withdrawing');
    }
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });
  };

  const getRoleBadge = (role) => {
    const labels = { batsman: 'BAT', bowler: 'BOWL', all_rounder: 'AR', wicket_keeper: 'WK' };
    return labels[role] || role;
  };

  const getRoleClass = (role) => {
    const classes = { batsman: 'role-bat', bowler: 'role-bowl', all_rounder: 'role-ar', wicket_keeper: 'role-wk' };
    return classes[role] || '';
  };

  const toggleEntryExpand = (entryId) => {
    setExpandedEntry(expandedEntry === entryId ? null : entryId);
    setExpandedPlayer(null);
  };

  const togglePlayerExpand = (e, playerId) => {
    e.stopPropagation();
    setExpandedPlayer(expandedPlayer === playerId ? null : playerId);
  };

  // Build detailed breakdown for a player's performance
  const buildPointsBreakdown = (perf) => {
    if (!perf) return [];
    const lines = [];

    // Batting
    if (perf.did_bat || perf.runs_scored > 0 || perf.balls_faced > 0) {
      if (perf.runs_scored > 0) lines.push({ label: `Runs (${perf.runs_scored})`, points: perf.runs_scored });
      if (perf.fours > 0) lines.push({ label: `Fours bonus (${perf.fours} × 1)`, points: perf.fours });
      if (perf.sixes > 0) lines.push({ label: `Sixes bonus (${perf.sixes} × 2)`, points: perf.sixes * 2 });
      if (perf.runs_scored >= 100) lines.push({ label: 'Century bonus', points: 16 });
      else if (perf.runs_scored >= 50) lines.push({ label: 'Half-century bonus', points: 8 });
      else if (perf.runs_scored >= 30) lines.push({ label: '30-run bonus', points: 4 });
      if (perf.is_duck) lines.push({ label: 'Duck penalty', points: -2 });
    }

    // Bowling
    if (perf.wickets > 0) lines.push({ label: `Wickets (${perf.wickets} × 25)`, points: perf.wickets * 25 });
    if (perf.lbw_bowled_count > 0) lines.push({ label: `LBW/Bowled bonus (${perf.lbw_bowled_count} × 8)`, points: perf.lbw_bowled_count * 8 });
    if (perf.wickets >= 5) lines.push({ label: '5-wicket bonus', points: 16 });
    if (perf.wickets >= 4) lines.push({ label: '4-wicket bonus', points: 8 });
    if (perf.wickets >= 3) lines.push({ label: '3-wicket bonus', points: 4 });
    if (perf.maidens > 0) lines.push({ label: `Maidens (${perf.maidens} × 12)`, points: perf.maidens * 12 });

    // Fielding
    if (perf.catches > 0) lines.push({ label: `Catches (${perf.catches} × 8)`, points: perf.catches * 8 });
    if (perf.stumpings > 0) lines.push({ label: `Stumpings (${perf.stumpings} × 12)`, points: perf.stumpings * 12 });
    if (perf.direct_run_outs > 0) lines.push({ label: `Direct run outs (${perf.direct_run_outs} × 12)`, points: perf.direct_run_outs * 12 });
    if (perf.indirect_run_outs > 0) lines.push({ label: `Indirect run outs (${perf.indirect_run_outs} × 6)`, points: perf.indirect_run_outs * 6 });

    return lines;
  };

  // Sort entries by total_points descending for leaderboard
  const sortedEntries = [...entries].sort((a, b) => (parseFloat(b.total_points) || 0) - (parseFloat(a.total_points) || 0));

  return (
    <div className="match-detail-page">
      <Link to="/" className="back-link">← Back to Matches</Link>

      <div className="match-hero">
        <span className="match-number-label">Match {match.match_number}</span>
        <div className="hero-teams">
          <div className="hero-team">
            <span className="hero-team-short">{match.team1.short_name}</span>
            <span className="hero-team-name">{match.team1.name}</span>
          </div>
          <div className="hero-vs">VS</div>
          <div className="hero-team">
            <span className="hero-team-short">{match.team2.short_name}</span>
            <span className="hero-team-name">{match.team2.name}</span>
          </div>
        </div>
        <div className="hero-meta">
          <span>📅 {formatDate(match.match_date)}</span>
          <span>📍 {match.venue}</span>
        </div>
        <span className={`status-badge status-${matchStarted && match.status === 'upcoming' ? 'live' : match.status}`}>
          {(match.status === 'live' || (matchStarted && match.status === 'upcoming')) && <span className="live-dot"></span>}
          {matchStarted && match.status === 'upcoming' ? 'started' : match.status}
        </span>
      </div>

      {/* Join / Pick Team CTA */}
      {!matchStarted && !userHasEntry && !is_full && (
        <button className="btn-cta" onClick={() => navigate(`/matches/${id}/pick`)}>
          🏏 Pick Your Team & Join
        </button>
      )}
      {userHasEntry && !matchStarted && (
        <div className="info-banner info-success" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>✅ You've picked your team! Teams will be revealed once the match starts.</span>
          <button className="btn-withdraw" onClick={handleWithdraw}>🔄 Withdraw & Re-pick</button>
        </div>
      )}
      {is_full && !userHasEntry && (
        <div className="info-banner info-warning">⚠️ This match is full (5/5 players joined)</div>
      )}

      {/* Entries / Leaderboard */}
      <div className="section">
        <h2 className="section-title">
          {match.status === 'completed' ? '🏆 Leaderboard' : `👥 Entries (${entries_count}/5)`}
        </h2>

        {sortedEntries.length === 0 ? (
          <div className="empty-state small">
            <p>No one has joined yet. Be the first!</p>
          </div>
        ) : (
          <div className="entries-list">
            {sortedEntries.map((entry, idx) => (
              <div key={entry.id} className={`entry-card ${idx === 0 && match.status === 'completed' ? 'winner' : ''}`}>
                <div
                  className="entry-header"
                  onClick={() => entry.team_visible && toggleEntryExpand(entry.id)}
                  style={{ cursor: entry.team_visible ? 'pointer' : 'default' }}
                >
                  <div className="entry-rank">
                    {match.status === 'completed' && (
                      <span className="rank-number">
                        {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `#${idx + 1}`}
                      </span>
                    )}
                    <span className="entry-user-avatar">{entry.user?.name?.[0]}</span>
                    <span className="entry-user-name">{entry.user?.name}</span>
                    {entry.user?.id === currentUser?.id && <span className="you-badge">You</span>}
                    {entry.team_visible && (
                      <span className="expand-hint">{expandedEntry === entry.id ? '▾' : '▸'}</span>
                    )}
                  </div>
                  {(match.status === 'completed' || match.status === 'live') && (
                    <span className="entry-points">{parseFloat(entry.total_points)?.toFixed(1) || '0.0'} pts</span>
                  )}
                </div>

                {/* Team details — visible only if match started or it's the user's own entry */}
                {entry.team_visible ? (
                  <div className="entry-team">
                    <div className="entry-players-grid">
                      {entry.selected_players?.map(player => (
                        <span
                          key={player.id}
                          className={`player-chip ${getRoleClass(player.role)} ${expandedPlayer === player.id ? 'chip-active' : ''}`}
                          onClick={(e) => player.performance && togglePlayerExpand(e, player.id)}
                          style={{ cursor: player.performance ? 'pointer' : 'default' }}
                        >
                          {player.name.split(' ').pop()}
                          <span className="chip-role">{getRoleBadge(player.role)}</span>
                          {entry.captain?.id === player.id && <span className="chip-badge captain">C</span>}
                          {entry.vice_captain?.id === player.id && <span className="chip-badge vc">VC</span>}
                          {player.performance && (
                            <span className="chip-pts">{player.performance.effective_points}</span>
                          )}
                        </span>
                      ))}
                    </div>

                    {/* Individual player breakdown popup */}
                    {expandedPlayer && entry.selected_players?.find(p => p.id === expandedPlayer)?.performance && (() => {
                      const player = entry.selected_players.find(p => p.id === expandedPlayer);
                      const perf = player.performance;
                      const breakdown = buildPointsBreakdown(perf);
                      return (
                        <div className="player-breakdown" onClick={(e) => e.stopPropagation()}>
                          <div className="breakdown-player-header">
                            <span className="breakdown-player-name">{player.name}</span>
                            {perf.multiplier > 1 && (
                              <span className={`breakdown-multiplier ${perf.multiplier === 2 ? 'captain' : 'vc'}`}>
                                {perf.multiplier === 2 ? 'Captain (2×)' : 'Vice Captain (1.5×)'}
                              </span>
                            )}
                          </div>
                          {perf.did_bat && (
                            <div className="breakdown-stat-line">
                              🏏 {perf.runs_scored}({perf.balls_faced}) • {perf.fours}×4s • {perf.sixes}×6s
                            </div>
                          )}
                          {perf.overs_bowled > 0 && (
                            <div className="breakdown-stat-line">
                              🎳 {perf.wickets}/{perf.runs_conceded} ({perf.overs_bowled} ov) • {perf.maidens} maiden{perf.maidens !== 1 ? 's' : ''}
                            </div>
                          )}
                          <div className="breakdown-lines">
                            {breakdown.map((line, i) => (
                              <div key={i} className="breakdown-line">
                                <span>{line.label}</span>
                                <span className={line.points >= 0 ? 'pts-positive' : 'pts-negative'}>
                                  {line.points >= 0 ? '+' : ''}{line.points}
                                </span>
                              </div>
                            ))}
                          </div>
                          <div className="breakdown-total">
                            <span>Base points</span>
                            <span>{perf.base_points}</span>
                          </div>
                          {perf.multiplier > 1 && (
                            <div className="breakdown-total grand">
                              <span>× {perf.multiplier} multiplier</span>
                              <span className="pts-highlight">{perf.effective_points}</span>
                            </div>
                          )}
                        </div>
                      );
                    })()}

                    {/* Full team breakdown when entry card expanded */}
                    {expandedEntry === entry.id && (
                      <div className="team-breakdown" onClick={(e) => e.stopPropagation()}>
                        <div className="team-breakdown-header">📊 Points Breakdown</div>
                        <div className="team-breakdown-table">
                          <div className="tb-row tb-header-row">
                            <span className="tb-player">Player</span>
                            <span className="tb-role">Role</span>
                            <span className="tb-stat">Batting</span>
                            <span className="tb-stat">Bowling</span>
                            <span className="tb-base">Base</span>
                            <span className="tb-mult">Mult</span>
                            <span className="tb-total">Points</span>
                          </div>
                          {entry.selected_players
                            ?.slice()
                            .sort((a, b) => (b.performance?.effective_points || 0) - (a.performance?.effective_points || 0))
                            .map(player => {
                              const perf = player.performance;
                              if (!perf) return (
                                <div key={player.id} className="tb-row">
                                  <span className="tb-player">{player.name.split(' ').pop()}</span>
                                  <span className="tb-role">{getRoleBadge(player.role)}</span>
                                  <span className="tb-stat">—</span>
                                  <span className="tb-stat">—</span>
                                  <span className="tb-base">0</span>
                                  <span className="tb-mult">1×</span>
                                  <span className="tb-total">0</span>
                                </div>
                              );
                              return (
                                <div key={player.id} className={`tb-row ${perf.multiplier > 1 ? 'tb-highlight' : ''}`}>
                                  <span className="tb-player">
                                    {player.name.split(' ').pop()}
                                    {entry.captain?.id === player.id && <span className="tb-badge captain">C</span>}
                                    {entry.vice_captain?.id === player.id && <span className="tb-badge vc">VC</span>}
                                  </span>
                                  <span className="tb-role">{getRoleBadge(player.role)}</span>
                                  <span className="tb-stat">
                                    {perf.did_bat ? `${perf.runs_scored}(${perf.balls_faced})` : '—'}
                                  </span>
                                  <span className="tb-stat">
                                    {perf.overs_bowled > 0 ? `${perf.wickets}/${perf.runs_conceded}` : '—'}
                                  </span>
                                  <span className="tb-base">{perf.base_points}</span>
                                  <span className="tb-mult">{perf.multiplier > 1 ? `${perf.multiplier}×` : '1×'}</span>
                                  <span className="tb-total">{perf.effective_points}</span>
                                </div>
                              );
                            })}
                          <div className="tb-row tb-total-row">
                            <span className="tb-player" style={{ fontWeight: 700 }}>Total</span>
                            <span className="tb-role"></span>
                            <span className="tb-stat"></span>
                            <span className="tb-stat"></span>
                            <span className="tb-base"></span>
                            <span className="tb-mult"></span>
                            <span className="tb-total" style={{ fontWeight: 700, color: 'var(--accent)' }}>
                              {parseFloat(entry.total_points)?.toFixed(1)}
                            </span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="team-hidden-banner">
                    🔒 Team hidden until match starts
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default MatchDetail;
