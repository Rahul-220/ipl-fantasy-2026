import { useState, useEffect } from 'react';
import { getTeams, getTeam, createPlayer, updatePlayer, deletePlayer } from '../api';

function Squads() {
  const [teams, setTeams] = useState([]);
  const [selectedTeamId, setSelectedTeamId] = useState(null);
  const [teamData, setTeamData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingPlayer, setEditingPlayer] = useState(null);
  const [formData, setFormData] = useState({ name: '', role: 'batsman' });
  const [message, setMessage] = useState('');

  useEffect(() => {
    getTeams().then(res => {
      setTeams(res.data);
      setLoading(false);
    });
  }, []);

  const loadTeam = async (teamId) => {
    setSelectedTeamId(teamId);
    setShowAddForm(false);
    setEditingPlayer(null);
    const res = await getTeam(teamId);
    setTeamData(res.data);
  };

  const handleAddPlayer = async (e) => {
    e.preventDefault();
    try {
      await createPlayer({ ...formData, ipl_team_id: selectedTeamId });
      setFormData({ name: '', role: 'batsman' });
      setShowAddForm(false);
      setMessage('Player added successfully!');
      loadTeam(selectedTeamId);
      // Refresh teams to update count
      getTeams().then(res => setTeams(res.data));
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      setMessage('Error: ' + (err.response?.data?.errors?.join(', ') || 'Failed to add player'));
    }
  };

  const handleEditPlayer = async (e) => {
    e.preventDefault();
    try {
      await updatePlayer(editingPlayer.id, formData);
      setEditingPlayer(null);
      setFormData({ name: '', role: 'batsman' });
      setMessage('Player updated successfully!');
      loadTeam(selectedTeamId);
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      setMessage('Error: ' + (err.response?.data?.errors?.join(', ') || 'Failed to update'));
    }
  };

  const handleDeletePlayer = async (playerId, playerName) => {
    if (!window.confirm(`Remove ${playerName} from the squad?`)) return;
    try {
      await deletePlayer(playerId);
      setMessage(`${playerName} removed from squad`);
      loadTeam(selectedTeamId);
      getTeams().then(res => setTeams(res.data));
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      setMessage('Error deleting player');
    }
  };

  const startEdit = (player) => {
    setEditingPlayer(player);
    setFormData({ name: player.name, role: player.role });
    setShowAddForm(false);
  };

  const cancelEdit = () => {
    setEditingPlayer(null);
    setFormData({ name: '', role: 'batsman' });
  };

  const getRoleBadge = (role) => {
    const labels = { batsman: 'BAT', bowler: 'BOWL', all_rounder: 'AR', wicket_keeper: 'WK' };
    return labels[role] || role;
  };

  const getRoleClass = (role) => {
    const classes = { batsman: 'role-bat', bowler: 'role-bowl', all_rounder: 'role-ar', wicket_keeper: 'role-wk' };
    return classes[role] || '';
  };

  const getRoleLabel = (role) => {
    const labels = { batsman: 'Batsmen', bowler: 'Bowlers', all_rounder: 'All Rounders', wicket_keeper: 'Wicket Keepers' };
    return labels[role] || role;
  };

  // Group players by role
  const roleOrder = ['wicket_keeper', 'batsman', 'all_rounder', 'bowler'];

  const groupedPlayers = teamData?.players?.reduce((acc, player) => {
    if (!acc[player.role]) acc[player.role] = [];
    acc[player.role].push(player);
    return acc;
  }, {}) || {};

  if (loading) {
    return <div className="loading-container"><div className="loader"></div><p>Loading teams...</p></div>;
  }

  return (
    <div className="squads-page">
      <div className="page-header">
        <h1>🏏 IPL 2026 Squads</h1>
        <p className="page-subtitle">View and manage team rosters</p>
      </div>

      {message && <div className="info-banner info-success">{message}</div>}

      <div className="squads-layout">
        {/* Team Cards */}
        <div className="teams-grid">
          {teams.map(team => (
            <button
              key={team.id}
              className={`team-card-btn ${selectedTeamId === team.id ? 'active' : ''}`}
              onClick={() => loadTeam(team.id)}
            >
              <span className="team-card-short">{team.short_name}</span>
              <span className="team-card-name">{team.name}</span>
              <span className="team-card-count">{team.players_count} players</span>
            </button>
          ))}
        </div>

        {/* Selected Team Roster */}
        {!selectedTeamId && (
          <div className="empty-state">
            <span className="empty-icon">👆</span>
            <p>Select a team above to view their squad</p>
          </div>
        )}

        {selectedTeamId && teamData && (
          <div className="squad-detail">
            <div className="squad-header">
              <div>
                <h2>{teamData.team.name}</h2>
                <span className="squad-count">{teamData.players.length} players</span>
              </div>
              <button
                className="btn-primary"
                onClick={() => { setShowAddForm(true); setEditingPlayer(null); setFormData({ name: '', role: 'batsman' }); }}
              >
                + Add Player
              </button>
            </div>

            {/* Add / Edit Form */}
            {(showAddForm || editingPlayer) && (
              <form
                className="player-form"
                onSubmit={editingPlayer ? handleEditPlayer : handleAddPlayer}
              >
                <h4>{editingPlayer ? `Edit: ${editingPlayer.name}` : 'Add New Player'}</h4>
                <div className="form-row">
                  <input
                    type="text"
                    placeholder="Player name"
                    value={formData.name}
                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                    required
                    className="form-input"
                  />
                  <select
                    value={formData.role}
                    onChange={e => setFormData({ ...formData, role: e.target.value })}
                    className="form-select"
                  >
                    <option value="batsman">Batsman</option>
                    <option value="bowler">Bowler</option>
                    <option value="all_rounder">All Rounder</option>
                    <option value="wicket_keeper">Wicket Keeper</option>
                  </select>
                  <button type="submit" className="btn-primary">
                    {editingPlayer ? 'Save' : 'Add'}
                  </button>
                  <button
                    type="button"
                    className="btn-back"
                    onClick={() => { setShowAddForm(false); cancelEdit(); }}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            )}

            {/* Players grouped by role */}
            {roleOrder.map(role => (
              groupedPlayers[role]?.length > 0 && (
                <div key={role} className="squad-role-section">
                  <h3 className="role-title">
                    {getRoleLabel(role)}
                    <span className="role-count">{groupedPlayers[role].length}</span>
                  </h3>
                  <div className="squad-players-list">
                    {groupedPlayers[role].map(player => (
                      <div key={player.id} className="squad-player-row">
                        <div className="squad-player-info">
                          <span className="squad-player-name">{player.name}</span>
                          <span className={`role-badge ${getRoleClass(player.role)}`}>
                            {getRoleBadge(player.role)}
                          </span>
                        </div>
                        <div className="squad-player-actions">
                          <button
                            className="action-btn edit-btn"
                            onClick={() => startEdit(player)}
                            title="Edit player"
                          >✏️</button>
                          <button
                            className="action-btn delete-btn"
                            onClick={() => handleDeletePlayer(player.id, player.name)}
                            title="Remove player"
                          >🗑️</button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default Squads;
