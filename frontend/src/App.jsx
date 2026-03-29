import { useState, useEffect, createContext, useContext } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { getUsers, loginUser, createUser } from './api';
import Home from './pages/Home';
import MatchDetail from './pages/MatchDetail';
import TeamPicker from './pages/TeamPicker';
import Admin from './pages/Admin';
import Leaderboard from './pages/Leaderboard';
import Squads from './pages/Squads';
import PointsSystem from './pages/PointsSystem';
import './App.css';

export const UserContext = createContext(null);

function NavBar() {
  const location = useLocation();
  const { currentUser, setCurrentUser } = useContext(UserContext);

  const isActive = (path) => location.pathname === path ? 'nav-link active' : 'nav-link';

  return (
    <nav className="navbar">
      <Link to="/" className="nav-brand">
        <span className="brand-icon">🏏</span>
        <span className="brand-text">IPL Fantasy</span>
      </Link>
      <div className="nav-links">
        <Link to="/" className={isActive('/')}>Matches</Link>
        <Link to="/squads" className={isActive('/squads')}>Squads</Link>
        <Link to="/leaderboard" className={isActive('/leaderboard')}>Leaderboard</Link>
        <Link to="/admin" className={isActive('/admin')}>Admin</Link>
        <Link to="/points" className={isActive('/points')}>Points</Link>
      </div>
      {currentUser && (
        <div className="nav-user">
          <span className="user-avatar">{currentUser.name[0]}</span>
          <span className="user-name">{currentUser.name}</span>
          <button className="logout-btn" onClick={() => { localStorage.removeItem('fantasyUser'); setCurrentUser(null); }}>↪</button>
        </div>
      )}
    </nav>
  );
}

function LoginScreen() {
  const { setCurrentUser } = useContext(UserContext);
  const [mode, setMode] = useState('login'); // 'login' or 'signup'
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!name.trim() || !password.trim()) return;
    setError('');
    setLoading(true);
    try {
      const res = await loginUser(name.trim(), password);
      setCurrentUser(res.data);
      localStorage.setItem('fantasyUser', JSON.stringify(res.data));
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    }
    setLoading(false);
  };

  const handleSignup = async (e) => {
    e.preventDefault();
    if (!name.trim() || !password.trim()) return;
    if (password.length < 4) {
      setError('Password must be at least 4 characters');
      return;
    }
    setError('');
    setLoading(true);
    try {
      const res = await createUser(name.trim(), password);
      setCurrentUser(res.data);
      localStorage.setItem('fantasyUser', JSON.stringify(res.data));
    } catch (err) {
      setError(err.response?.data?.errors?.join(', ') || 'Signup failed');
    }
    setLoading(false);
  };

  return (
    <div className="user-selector-overlay">
      <div className="user-selector-card">
        <div className="selector-header">
          <span className="selector-icon">🏏</span>
          <h1>IPL Fantasy 2026</h1>
          <p>Pick your players. Outscore your friends.</p>
        </div>

        <div className="login-tabs">
          <button
            className={`login-tab ${mode === 'login' ? 'active' : ''}`}
            onClick={() => { setMode('login'); setError(''); }}
          >
            Log In
          </button>
          <button
            className={`login-tab ${mode === 'signup' ? 'active' : ''}`}
            onClick={() => { setMode('signup'); setError(''); }}
          >
            Sign Up
          </button>
        </div>

        {error && <div className="login-error">{error}</div>}

        <form onSubmit={mode === 'login' ? handleLogin : handleSignup} className="login-form">
          <div className="login-field">
            <label>Name</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="Enter your name"
              maxLength={20}
              autoFocus
            />
          </div>
          <div className="login-field">
            <label>Password</label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder={mode === 'login' ? 'Enter password' : 'Create a password'}
            />
          </div>
          <button type="submit" className="btn-primary login-submit" disabled={loading}>
            {loading ? '...' : mode === 'login' ? 'Log In' : 'Create Account'}
          </button>
        </form>
      </div>
    </div>
  );
}

function App() {
  const [currentUser, setCurrentUser] = useState(() => {
    const saved = localStorage.getItem('fantasyUser');
    return saved ? JSON.parse(saved) : null;
  });

  if (!currentUser) {
    return (
      <UserContext.Provider value={{ currentUser, setCurrentUser }}>
        <LoginScreen />
      </UserContext.Provider>
    );
  }

  return (
    <UserContext.Provider value={{ currentUser, setCurrentUser }}>
      <Router>
        <div className="app">
          <NavBar />
          <main className="main-content">
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/matches/:id" element={<MatchDetail />} />
              <Route path="/matches/:id/pick" element={<TeamPicker />} />
              <Route path="/admin" element={<Admin />} />
              <Route path="/squads" element={<Squads />} />
              <Route path="/leaderboard" element={<Leaderboard />} />
              <Route path="/points" element={<PointsSystem />} />
            </Routes>
          </main>
        </div>
      </Router>
    </UserContext.Provider>
  );
}

export default App;
