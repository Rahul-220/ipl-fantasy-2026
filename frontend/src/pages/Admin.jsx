import { useState, useEffect } from 'react';
import { getMatches, getMatch, getTeams, getPerformances, savePerformance, calculatePoints, updateMatchStatus, createMatch, syncMatch, toggleAutoSync } from '../api';

function Admin() {
  const [matches, setMatches] = useState([]);
  const [teams, setTeams] = useState([]);
  const [selectedMatchId, setSelectedMatchId] = useState(null);
  const [matchData, setMatchData] = useState(null);
  const [performances, setPerformances] = useState({});
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [showAddMatch, setShowAddMatch] = useState(false);
  const [syncLog, setSyncLog] = useState([]);
  const [syncing, setSyncing] = useState(false);
  const [newMatch, setNewMatch] = useState({
    team1_id: '', team2_id: '', match_date: '', venue: '', match_number: ''
  });

  useEffect(() => {
    getMatches().then(res => setMatches(res.data));
    getTeams().then(res => setTeams(res.data));
  }, []);

  const loadMatch = async (matchId) => {
    setSelectedMatchId(matchId);
    setShowAddMatch(false);
    setLoading(true);
    setMessage('');
    setSyncLog([]);
    try {
      const [matchRes, perfRes] = await Promise.all([
        getMatch(matchId),
        getPerformances(matchId)
      ]);
      setMatchData(matchRes.data);

      const perfMap = {};
      perfRes.data.forEach(p => {
        perfMap[p.ipl_player_id] = {
          id: p.id,
          runs_scored: p.runs_scored || 0,
          balls_faced: p.balls_faced || 0,
          fours: p.fours || 0,
          sixes: p.sixes || 0,
          is_duck: p.is_duck || false,
          did_bat: p.did_bat || false,
          overs_bowled: p.overs_bowled || 0,
          maidens: p.maidens || 0,
          runs_conceded: p.runs_conceded || 0,
          wickets: p.wickets || 0,
          lbw_bowled_count: p.lbw_bowled_count || 0,
          catches: p.catches || 0,
          stumpings: p.stumpings || 0,
          direct_run_outs: p.direct_run_outs || 0,
          indirect_run_outs: p.indirect_run_outs || 0,
          fantasy_points: p.fantasy_points || 0,
        };
      });
      setPerformances(perfMap);
    } catch (err) {
      setMessage('Error loading match data');
    }
    setLoading(false);
  };

  const updateField = (playerId, field, value) => {
    setPerformances(prev => ({
      ...prev,
      [playerId]: {
        ...(prev[playerId] || {}),
        [field]: value,
      }
    }));
  };

  const savePlayerPerformance = async (playerId) => {
    const data = performances[playerId] || {};
    try {
      await savePerformance(selectedMatchId, {
        ipl_player_id: playerId,
        ...data,
      });
      setMessage(`Saved performance for player successfully!`);
      const perfRes = await getPerformances(selectedMatchId);
      const perfMap = {};
      perfRes.data.forEach(p => {
        perfMap[p.ipl_player_id] = {
          id: p.id,
          runs_scored: p.runs_scored || 0,
          balls_faced: p.balls_faced || 0,
          fours: p.fours || 0,
          sixes: p.sixes || 0,
          is_duck: p.is_duck || false,
          did_bat: p.did_bat || false,
          overs_bowled: p.overs_bowled || 0,
          maidens: p.maidens || 0,
          runs_conceded: p.runs_conceded || 0,
          wickets: p.wickets || 0,
          lbw_bowled_count: p.lbw_bowled_count || 0,
          catches: p.catches || 0,
          stumpings: p.stumpings || 0,
          direct_run_outs: p.direct_run_outs || 0,
          indirect_run_outs: p.indirect_run_outs || 0,
          fantasy_points: p.fantasy_points || 0,
        };
      });
      setPerformances(perfMap);
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      setMessage('Error saving performance');
    }
  };

  const handleCalculatePoints = async () => {
    try {
      await calculatePoints(selectedMatchId);
      setMessage('Points calculated! Check leaderboard.');
    } catch (err) {
      setMessage('Error calculating points');
    }
  };

  const handleStatusUpdate = async (status) => {
    try {
      await updateMatchStatus(selectedMatchId, status);
      setMessage(`Match status updated to ${status}`);
      getMatches().then(res => setMatches(res.data));
    } catch (err) {
      setMessage('Error updating status');
    }
  };

  const handleSyncMatch = async () => {
    setSyncing(true);
    setSyncLog(['🔄 Syncing from CricAPI...']);
    setMessage('');
    try {
      const res = await syncMatch(selectedMatchId);
      setSyncLog(res.data.log || []);
      if (res.data.success) {
        setMessage(`✅ Synced! ${res.data.performances} performances updated.`);
        // Reload match data and performances
        loadMatch(selectedMatchId);
        getMatches().then(r => setMatches(r.data));
      } else {
        setMessage('⚠️ Sync completed with issues — check log below.');
      }
    } catch (err) {
      setSyncLog(['❌ Sync failed: ' + (err.response?.data?.error || err.message)]);
      setMessage('Error syncing match');
    }
    setSyncing(false);
  };

  const handleToggleAutoSync = async () => {
    try {
      const res = await toggleAutoSync(selectedMatchId);
      setMessage(res.data.message);
      getMatches().then(r => setMatches(r.data));
    } catch (err) {
      setMessage('Error toggling auto-sync');
    }
  };

  const handleAddMatch = async (e) => {
    e.preventDefault();
    try {
      await createMatch(newMatch);
      setMessage('Match added successfully!');
      setShowAddMatch(false);
      setNewMatch({ team1_id: '', team2_id: '', match_date: '', venue: '', match_number: '' });
      getMatches().then(res => setMatches(res.data));
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      setMessage('Error: ' + (err.response?.data?.errors?.join(', ') || 'Failed to add match'));
    }
  };

  const getRoleBadge = (role) => {
    const labels = { batsman: 'BAT', bowler: 'BOWL', all_rounder: 'AR', wicket_keeper: 'WK' };
    return labels[role] || role;
  };

  const getSelectedMatch = () => matches.find(m => m.id === selectedMatchId);

  return (
    <div className="admin-page">
      <h1>⚙️ Admin Panel</h1>

      {message && <div className="info-banner info-success">{message}</div>}

      <div className="admin-layout">
        {/* Match Selector Sidebar */}
        <div className="admin-sidebar">
          <h3>Select Match</h3>
          <button
            className="btn-primary"
            style={{ width: '100%', marginBottom: '12px', fontSize: '13px', padding: '10px' }}
            onClick={() => { setShowAddMatch(true); setSelectedMatchId(null); setMatchData(null); }}
          >
            + Add Match
          </button>
          <div className="admin-match-list">
            {matches.map(m => (
              <button
                key={m.id}
                className={`admin-match-btn ${selectedMatchId === m.id ? 'active' : ''}`}
                onClick={() => loadMatch(m.id)}
              >
                <span className="admin-match-num">#{m.match_number}</span>
                <span>{m.team1.short_name} vs {m.team2.short_name}</span>
                <span style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                  {m.auto_sync && <span title="Auto-sync enabled" style={{ fontSize: '10px' }}>🔄</span>}
                  <span className={`status-dot status-${m.status}`}></span>
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Main Content */}
        <div className="admin-content">
          {/* Add Match Form */}
          {showAddMatch && (
            <div className="add-match-form-wrapper">
              <h2>📅 Add New Match</h2>
              <p style={{ color: 'var(--text-secondary)', marginBottom: '20px', fontSize: '14px' }}>
                Add a new match to the schedule. Match number auto-increments if left blank.
              </p>
              <form onSubmit={handleAddMatch} className="add-match-form">
                <div className="form-grid">
                  <div className="form-field">
                    <label>Team 1</label>
                    <select
                      value={newMatch.team1_id}
                      onChange={e => setNewMatch({ ...newMatch, team1_id: e.target.value })}
                      className="form-select"
                      required
                    >
                      <option value="">Select team...</option>
                      {teams.map(t => (
                        <option key={t.id} value={t.id}>{t.short_name} — {t.name}</option>
                      ))}
                    </select>
                  </div>
                  <div className="form-field">
                    <label>Team 2</label>
                    <select
                      value={newMatch.team2_id}
                      onChange={e => setNewMatch({ ...newMatch, team2_id: e.target.value })}
                      className="form-select"
                      required
                    >
                      <option value="">Select team...</option>
                      {teams.map(t => (
                        <option key={t.id} value={t.id}>{t.short_name} — {t.name}</option>
                      ))}
                    </select>
                  </div>
                  <div className="form-field">
                    <label>Date & Time (IST)</label>
                    <input
                      type="datetime-local"
                      value={newMatch.match_date}
                      onChange={e => setNewMatch({ ...newMatch, match_date: e.target.value })}
                      className="form-input"
                      required
                    />
                  </div>
                  <div className="form-field">
                    <label>Venue</label>
                    <input
                      type="text"
                      value={newMatch.venue}
                      onChange={e => setNewMatch({ ...newMatch, venue: e.target.value })}
                      className="form-input"
                      placeholder="e.g. Wankhede Stadium, Mumbai"
                      required
                    />
                  </div>
                  <div className="form-field">
                    <label>Match # (optional)</label>
                    <input
                      type="number"
                      value={newMatch.match_number}
                      onChange={e => setNewMatch({ ...newMatch, match_number: e.target.value })}
                      className="form-input"
                      placeholder="Auto"
                      min="1"
                    />
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                  <button type="submit" className="btn-primary">Add Match</button>
                  <button
                    type="button"
                    className="btn-back"
                    onClick={() => setShowAddMatch(false)}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Empty State */}
          {!selectedMatchId && !showAddMatch && (
            <div className="empty-state">
              <p>Select a match from the sidebar to enter player performances</p>
            </div>
          )}

          {loading && <div className="loading-container"><div className="loader"></div></div>}

          {/* Performance Table */}
          {selectedMatchId && matchData && !loading && (
            <>
              <div className="admin-match-header">
                <h2>{matchData.match.team1.short_name} vs {matchData.match.team2.short_name} — Match {matchData.match.match_number}</h2>
                <div className="admin-actions">
                  <select
                    value={matchData.match.status}
                    onChange={(e) => handleStatusUpdate(e.target.value)}
                    className="status-select"
                  >
                    <option value="upcoming">Upcoming</option>
                    <option value="live">Live</option>
                    <option value="completed">Completed</option>
                  </select>
                  <button className="btn-primary" onClick={handleCalculatePoints}>
                    🔢 Calculate Points
                  </button>
                </div>
              </div>

              {/* CricAPI Sync Controls */}
              <div className="sync-controls">
                <div className="sync-header">
                  <h3>📡 Live API Sync</h3>
                  <div className="sync-status">
                    {getSelectedMatch()?.last_synced_at && (
                      <span className="sync-time">
                        Last sync: {new Date(getSelectedMatch().last_synced_at).toLocaleTimeString()}
                      </span>
                    )}
                    {getSelectedMatch()?.cricapi_match_id && (
                      <span className="sync-id" title={getSelectedMatch().cricapi_match_id}>
                        🔗 Linked
                      </span>
                    )}
                  </div>
                </div>
                <div className="sync-actions">
                  <button
                    className={`btn-sync ${syncing ? 'syncing' : ''}`}
                    onClick={handleSyncMatch}
                    disabled={syncing}
                  >
                    {syncing ? '🔄 Syncing...' : '📥 Sync from CricAPI'}
                  </button>
                  <button
                    className={`btn-auto-sync ${getSelectedMatch()?.auto_sync ? 'active' : ''}`}
                    onClick={handleToggleAutoSync}
                  >
                    {getSelectedMatch()?.auto_sync ? '⏸️ Auto-Sync ON' : '▶️ Auto-Sync OFF'}
                  </button>
                </div>

                {/* Sync Log */}
                {syncLog.length > 0 && (
                  <div className="sync-log">
                    {syncLog.map((line, i) => (
                      <div key={i} className="sync-log-line">{line}</div>
                    ))}
                  </div>
                )}
              </div>

              <div className="performance-table-wrapper">
                <table className="performance-table">
                  <thead>
                    <tr>
                      <th>Player</th>
                      <th>Role</th>
                      <th>Team</th>
                      <th>Bat?</th>
                      <th>Runs</th>
                      <th>Balls</th>
                      <th>4s</th>
                      <th>6s</th>
                      <th>Duck</th>
                      <th>Overs</th>
                      <th>Wkts</th>
                      <th>Maidens</th>
                      <th>LBW/B</th>
                      <th>Catch</th>
                      <th>Stump</th>
                      <th>RO(D)</th>
                      <th>RO(I)</th>
                      <th>Pts</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {matchData.players?.map(player => {
                      const perf = performances[player.id] || {};
                      return (
                        <tr key={player.id}>
                          <td className="player-name-cell">{player.name}</td>
                          <td><span className={`role-badge-sm`}>{getRoleBadge(player.role)}</span></td>
                          <td>{player.ipl_team.short_name}</td>
                          <td>
                            <input type="checkbox" checked={!!perf.did_bat}
                              onChange={e => updateField(player.id, 'did_bat', e.target.checked)} />
                          </td>
                          <td><input type="number" min="0" className="perf-input" value={perf.runs_scored || 0}
                            onChange={e => updateField(player.id, 'runs_scored', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input" value={perf.balls_faced || 0}
                            onChange={e => updateField(player.id, 'balls_faced', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.fours || 0}
                            onChange={e => updateField(player.id, 'fours', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.sixes || 0}
                            onChange={e => updateField(player.id, 'sixes', parseInt(e.target.value) || 0)} /></td>
                          <td>
                            <input type="checkbox" checked={!!perf.is_duck}
                              onChange={e => updateField(player.id, 'is_duck', e.target.checked)} />
                          </td>
                          <td><input type="number" min="0" step="0.1" className="perf-input" value={perf.overs_bowled || 0}
                            onChange={e => updateField(player.id, 'overs_bowled', parseFloat(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.wickets || 0}
                            onChange={e => updateField(player.id, 'wickets', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.maidens || 0}
                            onChange={e => updateField(player.id, 'maidens', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.lbw_bowled_count || 0}
                            onChange={e => updateField(player.id, 'lbw_bowled_count', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.catches || 0}
                            onChange={e => updateField(player.id, 'catches', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.stumpings || 0}
                            onChange={e => updateField(player.id, 'stumpings', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.direct_run_outs || 0}
                            onChange={e => updateField(player.id, 'direct_run_outs', parseInt(e.target.value) || 0)} /></td>
                          <td><input type="number" min="0" className="perf-input sm" value={perf.indirect_run_outs || 0}
                            onChange={e => updateField(player.id, 'indirect_run_outs', parseInt(e.target.value) || 0)} /></td>
                          <td className="points-cell">{parseFloat(perf.fantasy_points)?.toFixed(1) || '—'}</td>
                          <td>
                            <button className="btn-save-sm" onClick={() => savePlayerPerformance(player.id)}>💾</button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export default Admin;
