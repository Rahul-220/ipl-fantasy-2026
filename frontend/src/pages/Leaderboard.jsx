import { useState, useEffect } from 'react';
import { getLeaderboard } from '../api';

function Leaderboard() {
  const [standings, setStandings] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getLeaderboard().then(res => {
      setStandings(res.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="loading-container"><div className="loader"></div><p>Loading leaderboard...</p></div>;
  }

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
                <tr key={entry.user_id} className={idx === 0 ? 'top-rank' : ''}>
                  <td className="rank-cell">
                    {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `#${idx + 1}`}
                  </td>
                  <td className="player-cell">
                    <span className="lb-avatar">{entry.user_name[0]}</span>
                    <span className="lb-name">{entry.user_name}</span>
                  </td>
                  <td>{entry.matches_played}</td>
                  <td className="points-cell highlight">{entry.total_points.toFixed(1)}</td>
                  <td>{(entry.total_points / entry.matches_played).toFixed(1)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default Leaderboard;
