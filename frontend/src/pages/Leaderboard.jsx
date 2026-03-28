import { useState, useEffect, Fragment } from 'react';
import { Link } from 'react-router-dom';
import { getLeaderboard } from '../api';

function Leaderboard() {
  const [standings, setStandings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expandedUser, setExpandedUser] = useState(null);

  useEffect(() => {
    getLeaderboard().then(res => {
      setStandings(res.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="loading-container"><div className="loader"></div><p>Loading leaderboard...</p></div>;
  }

  const toggleExpand = (userId) => {
    setExpandedUser(expandedUser === userId ? null : userId);
  };

  return (
    <div className="leaderboard-page">
      <div className="page-header">
        <h1>🏆 Season Leaderboard</h1>
        <p className="page-subtitle">Overall standings across all completed matches</p>
      </div>

      {standings.length === 0 ? (
        <div className="empty-state">
          <span className="empty-icon">🏆</span>
          <p>No completed matches yet. Leaderboard will appear after the first match is completed.</p>
        </div>
      ) : (
        <div className="leaderboard-table-wrapper">
          <table className="leaderboard-table">
            <thead>
              <tr>
                <th>Rank</th>
                <th>Player</th>
                <th>Matches Played</th>
                <th>Total Points</th>
                <th>Avg Points</th>
              </tr>
            </thead>
            <tbody>
              {standings.map((entry, idx) => (
                <Fragment key={entry.user_id}>
                  <tr
                    className={`${idx === 0 ? 'top-rank' : ''} ${entry.match_breakdown?.length > 0 ? 'expandable-row' : ''}`}
                    onClick={() => entry.match_breakdown?.length > 0 && toggleExpand(entry.user_id)}
                    style={{ cursor: entry.match_breakdown?.length > 0 ? 'pointer' : 'default' }}
                  >
                    <td className="rank-cell">
                      {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `#${idx + 1}`}
                    </td>
                    <td className="player-cell">
                      <span className="lb-avatar">{entry.user_name[0]}</span>
                      <span className="lb-name">{entry.user_name}</span>
                      {entry.match_breakdown?.length > 0 && (
                        <span className="expand-icon">{expandedUser === entry.user_id ? '▾' : '▸'}</span>
                      )}
                    </td>
                    <td>{entry.matches_played}</td>
                    <td className="points-cell highlight">{entry.total_points.toFixed(1)}</td>
                    <td>{(entry.total_points / entry.matches_played).toFixed(1)}</td>
                  </tr>
                  {expandedUser === entry.user_id && entry.match_breakdown?.length > 0 && (
                    <tr key={`${entry.user_id}-breakdown`} className="breakdown-row">
                      <td colSpan={5}>
                        <div className="match-breakdown">
                          <div className="breakdown-header">Match-wise Points</div>
                          <div className="breakdown-grid">
                            {entry.match_breakdown.map((mb) => (
                              <Link
                                to={`/matches/${mb.match_id}`}
                                key={mb.match_id}
                                className="breakdown-card"
                              >
                                <span className="breakdown-match-num">M{mb.match_number}</span>
                                <span className="breakdown-label">{mb.match_label}</span>
                                <span className="breakdown-points">{mb.points.toFixed(1)} pts</span>
                              </Link>
                            ))}
                          </div>
                        </div>
                      </td>
                    </tr>
                  )}
                </Fragment>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default Leaderboard;
