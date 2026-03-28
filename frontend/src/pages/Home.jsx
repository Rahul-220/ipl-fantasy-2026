import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getMatches } from '../api';

function Home() {
  const [matches, setMatches] = useState([]);
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getMatches().then(res => {
      setMatches(res.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  const filteredMatches = matches.filter(m => {
    if (filter === 'all') return true;
    return m.status === filter;
  });

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  };

  const formatTime = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleTimeString('en-IN', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'upcoming': return 'status-upcoming';
      case 'live': return 'status-live';
      case 'completed': return 'status-completed';
      default: return '';
    }
  };

  // Group matches by date
  const groupedMatches = filteredMatches.reduce((groups, match) => {
    const date = formatDate(match.match_date);
    if (!groups[date]) groups[date] = [];
    groups[date].push(match);
    return groups;
  }, {});

  if (loading) {
    return <div className="loading-container"><div className="loader"></div><p>Loading matches...</p></div>;
  }

  return (
    <div className="home-page">
      <div className="page-header">
        <h1>IPL 2026 Matches</h1>
        <div className="filter-tabs">
          {['all', 'upcoming', 'live', 'completed'].map(f => (
            <button
              key={f}
              className={`filter-tab ${filter === f ? 'active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f === 'all' ? 'All' : f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {Object.keys(groupedMatches).length === 0 ? (
        <div className="empty-state">
          <span className="empty-icon">📅</span>
          <p>No matches found</p>
        </div>
      ) : (
        Object.entries(groupedMatches).map(([date, dayMatches]) => (
          <div key={date} className="date-group">
            <h3 className="date-header">{date}</h3>
            <div className="matches-grid">
              {dayMatches.map(match => (
                <Link to={`/matches/${match.id}`} key={match.id} className="match-card">
                  <div className="match-card-header">
                    <span className="match-number">Match {match.match_number}</span>
                    {(() => {
                      const started = match.status !== 'upcoming' || new Date(match.match_date) <= new Date();
                      const displayStatus = started && match.status === 'upcoming' ? 'live' : match.status;
                      const displayLabel = started && match.status === 'upcoming' ? 'started' : match.status;
                      return (
                        <span className={`status-badge ${getStatusClass(displayStatus)}`}>
                          {(displayStatus === 'live') && <span className="live-dot"></span>}
                          {displayLabel}
                        </span>
                      );
                    })()}
                  </div>

                  <div className="match-teams">
                    <div className="team">
                      <span className="team-short">{match.team1.short_name}</span>
                      <span className="team-name">{match.team1.name}</span>
                    </div>
                    <span className="vs">VS</span>
                    <div className="team">
                      <span className="team-short">{match.team2.short_name}</span>
                      <span className="team-name">{match.team2.name}</span>
                    </div>
                  </div>

                  <div className="match-meta">
                    <span className="match-time">🕐 {formatTime(match.match_date)}</span>
                    <span className="match-venue">📍 {match.venue}</span>
                  </div>

                  <div className="match-footer">
                    <span className="entries-count">
                      👥 {match.entries_count}/5 joined
                    </span>
                    {match['full?'] && <span className="full-badge">FULL</span>}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  );
}

export default Home;
