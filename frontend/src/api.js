import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:3001';

const api = axios.create({
  baseURL: `${API_BASE}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Users
export const getUsers = () => api.get('/users');
export const createUser = (name, password) => api.post('/users', { name, password });
export const loginUser = (name, password) => api.post('/users/login', { name, password });

// Teams
export const getTeams = () => api.get('/ipl_teams');
export const getTeam = (id) => api.get(`/ipl_teams/${id}`);

// Players
export const getPlayers = (teamId) => api.get('/ipl_players', { params: { team_id: teamId } });
export const createPlayer = (data) => api.post('/ipl_players', data);
export const updatePlayer = (id, data) => api.put(`/ipl_players/${id}`, data);
export const deletePlayer = (id) => api.delete(`/ipl_players/${id}`);

// Matches
export const getMatches = () => api.get('/matches');
export const getMatch = (id, userId) => api.get(`/matches/${id}`, { params: { user_id: userId } });
export const getMatchLeaderboard = (id) => api.get(`/matches/${id}/leaderboard`);

// Match Entries
export const getMatchEntries = (matchId, userId) => api.get(`/matches/${matchId}/entries`, { params: { user_id: userId } });
export const createMatchEntry = (matchId, data) => api.post(`/matches/${matchId}/entries`, data);
export const deleteMatchEntry = (matchId, entryId) => api.delete(`/matches/${matchId}/entries/${entryId}`);

// Admin
export const getPerformances = (matchId) => api.get(`/admin/matches/${matchId}/performances`);
export const savePerformance = (matchId, data) => api.post(`/admin/matches/${matchId}/performances`, data);
export const updatePerformance = (matchId, perfId, data) => api.put(`/admin/matches/${matchId}/performances/${perfId}`, data);
export const calculatePoints = (matchId) => api.post(`/admin/matches/${matchId}/calculate_points`);
export const updateMatchStatus = (matchId, status) => api.post(`/admin/matches/${matchId}/update_status`, { status });
export const createMatch = (data) => api.post('/admin/matches', data);
export const syncMatch = (matchId) => api.post(`/admin/matches/${matchId}/sync_match`);
export const toggleAutoSync = (matchId) => api.post(`/admin/matches/${matchId}/toggle_auto_sync`);
export const setCricapiId = (matchId, cricapiId) => api.post(`/admin/matches/${matchId}/set_cricapi_id`, { cricapi_match_id: cricapiId });

// Leaderboard
export const getLeaderboard = () => api.get('/leaderboard');

export default api;
