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
                <div className="entry-header">
                  <div className="entry-rank">
                    {match.status === 'completed' && (
                      <span className="rank-number">
                        {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `#${idx + 1}`}
                      </span>
                    )}
                    <span className="entry-user-avatar">{entry.user?.name?.[0]}</span>
                    <span className="entry-user-name">{entry.user?.name}</span>
                    {entry.user?.id === currentUser?.id && <span className="you-badge">You</span>}
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
                        <span key={player.id} className={`player-chip ${getRoleClass(player.role)}`}>
                          {player.name.split(' ').pop()}
                          <span className="chip-role">{getRoleBadge(player.role)}</span>
                          {entry.captain?.id === player.id && <span className="chip-badge captain">C</span>}
                          {entry.vice_captain?.id === player.id && <span className="chip-badge vc">VC</span>}
                        </span>
                      ))}
                    </div>
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
