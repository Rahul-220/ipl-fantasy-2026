import { useState, useEffect, useContext } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getMatch, createMatchEntry } from '../api';
import { UserContext } from '../App';

function TeamPicker() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { currentUser } = useContext(UserContext);
  const [matchData, setMatchData] = useState(null);
  const [selectedPlayers, setSelectedPlayers] = useState([]);
  const [captainId, setCaptainId] = useState(null);
  const [vcId, setVcId] = useState(null);
  const [step, setStep] = useState(1); // 1: pick players, 2: pick C/VC
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [teamFilter, setTeamFilter] = useState('all');

  useEffect(() => {
    getMatch(id).then(res => {
      setMatchData(res.data);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [id]);

  if (loading) {
    return <div className="loading-container"><div className="loader"></div><p>Loading players...</p></div>;
  }

  if (!matchData) {
    return <div className="error-state">Match not found</div>;
  }

  const { match, players } = matchData;

  const togglePlayer = (playerId) => {
    if (selectedPlayers.includes(playerId)) {
      setSelectedPlayers(prev => prev.filter(id => id !== playerId));
    } else if (selectedPlayers.length < 11) {
      setSelectedPlayers(prev => [...prev, playerId]);
    }
  };

  const handleSubmit = async () => {
    setSubmitting(true);
    setError('');
    try {
      await createMatchEntry(id, {
        user_id: currentUser.id,
        player_ids: selectedPlayers,
        captain_id: captainId,
        vice_captain_id: vcId,
      });
      navigate(`/matches/${id}`);
    } catch (err) {
      setError(err.response?.data?.error || 'Something went wrong');
      setSubmitting(false);
    }
  };

  const getRoleBadge = (role) => {
    const labels = { batsman: 'BAT', bowler: 'BOWL', all_rounder: 'AR', wicket_keeper: 'WK' };
    return labels[role] || role;
  };

  const getRoleClass = (role) => {
    const classes = { batsman: 'role-bat', bowler: 'role-bowl', all_rounder: 'role-ar', wicket_keeper: 'role-wk' };
    return classes[role] || '';
  };

  // Group players by role
  const roleOrder = ['wicket_keeper', 'batsman', 'all_rounder', 'bowler'];
  const roleLabels = { wicket_keeper: 'Wicket Keepers', batsman: 'Batsmen', all_rounder: 'All Rounders', bowler: 'Bowlers' };

  const filteredPlayers = teamFilter === 'all'
    ? players
    : players.filter(p => p.ipl_team.id === parseInt(teamFilter));

  const groupedPlayers = roleOrder.reduce((acc, role) => {
    acc[role] = filteredPlayers.filter(p => p.role === role);
    return acc;
  }, {});

  const selectedPlayerObjects = players.filter(p => selectedPlayers.includes(p.id));

  return (
    <div className="team-picker-page">
      <div className="picker-header">
        <h1>Pick Your Team</h1>
        <div className="picker-match-info">
          <span>{match.team1.short_name} vs {match.team2.short_name}</span>
          <span>Match {match.match_number}</span>
        </div>
      </div>

      {error && <div className="info-banner info-error">❌ {error}</div>}

      {/* Progress */}
      <div className="picker-progress">
        <div className={`progress-step ${step >= 1 ? 'active' : ''}`}>
          <span className="step-num">1</span>
          <span>Select 11 Players</span>
        </div>
        <div className="progress-line"></div>
        <div className={`progress-step ${step >= 2 ? 'active' : ''}`}>
          <span className="step-num">2</span>
          <span>Pick C & VC</span>
        </div>
      </div>

      {step === 1 && (
        <>
          <div className="selection-counter">
            <span className={selectedPlayers.length === 11 ? 'counter-complete' : ''}>
              {selectedPlayers.length}/11 selected
            </span>
            {selectedPlayers.length === 11 && (
              <button className="btn-primary" onClick={() => setStep(2)}>
                Next: Pick Captain →
              </button>
            )}
          </div>

          {/* Team filter */}
          <div className="team-filter">
            <button
              className={`filter-btn ${teamFilter === 'all' ? 'active' : ''}`}
              onClick={() => setTeamFilter('all')}
            >All</button>
            <button
              className={`filter-btn ${teamFilter === String(match.team1.id) ? 'active' : ''}`}
              onClick={() => setTeamFilter(String(match.team1.id))}
            >{match.team1.short_name}</button>
            <button
              className={`filter-btn ${teamFilter === String(match.team2.id) ? 'active' : ''}`}
              onClick={() => setTeamFilter(String(match.team2.id))}
            >{match.team2.short_name}</button>
          </div>

          {roleOrder.map(role => (
            groupedPlayers[role]?.length > 0 && (
              <div key={role} className="role-section">
                <h3 className="role-title">{roleLabels[role]}</h3>
                <div className="players-list">
                  {groupedPlayers[role].map(player => (
                    <div
                      key={player.id}
                      className={`player-row ${selectedPlayers.includes(player.id) ? 'selected' : ''}`}
                      onClick={() => togglePlayer(player.id)}
                    >
                      <div className="player-info">
                        <span className="player-name">{player.name}</span>
                        <span className={`role-badge ${getRoleClass(player.role)}`}>{getRoleBadge(player.role)}</span>
                        <span className="player-team-badge">{player.ipl_team.short_name}</span>
                      </div>
                      <div className={`select-indicator ${selectedPlayers.includes(player.id) ? 'checked' : ''}`}>
                        {selectedPlayers.includes(player.id) ? '✓' : '+'}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )
          ))}
        </>
      )}

      {step === 2 && (
        <div className="captain-picker">
          <button className="btn-back" onClick={() => setStep(1)}>← Back to player selection</button>

          <p className="captain-instructions">
            Select your <strong>Captain (2x points)</strong> and <strong>Vice-Captain (1.5x points)</strong>
          </p>

          <div className="captain-grid">
            {selectedPlayerObjects.map(player => (
              <div key={player.id} className="captain-card">
                <div className="captain-card-info">
                  <span className="player-name">{player.name}</span>
                  <span className={`role-badge ${getRoleClass(player.role)}`}>{getRoleBadge(player.role)}</span>
                  <span className="player-team-badge">{player.ipl_team.short_name}</span>
                </div>
                <div className="captain-actions">
                  <button
                    className={`captain-btn ${captainId === player.id ? 'active-c' : ''}`}
                    onClick={() => {
                      if (vcId === player.id) setVcId(null);
                      setCaptainId(player.id);
                    }}
                  >C</button>
                  <button
                    className={`captain-btn ${vcId === player.id ? 'active-vc' : ''}`}
                    onClick={() => {
                      if (captainId === player.id) setCaptainId(null);
                      setVcId(player.id);
                    }}
                  >VC</button>
                </div>
              </div>
            ))}
          </div>

          {captainId && vcId && (
            <button
              className="btn-cta submit-btn"
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? 'Submitting...' : '🏏 Submit Your Team'}
            </button>
          )}
        </div>
      )}
    </div>
  );
}

export default TeamPicker;
