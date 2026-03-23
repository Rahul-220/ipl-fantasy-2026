import { useState, useEffect, createContext, useContext } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { getUsers, createUser } from './api';
import Home from './pages/Home';
import MatchDetail from './pages/MatchDetail';
import TeamPicker from './pages/TeamPicker';
import Admin from './pages/Admin';
import Leaderboard from './pages/Leaderboard';
import Squads from './pages/Squads';
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

function UserSelector() {
  const [users, setUsers] = useState([]);
  const [newName, setNewName] = useState('');
  const { setCurrentUser } = useContext(UserContext);

  useEffect(() => {
    getUsers().then(res => setUsers(res.data));
  }, []);

  const handleSelect = (user) => {
    setCurrentUser(user);
    localStorage.setItem('fantasyUser', JSON.stringify(user));
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!newName.trim()) return;
    const res = await createUser(newName.trim());
    setCurrentUser(res.data);
    localStorage.setItem('fantasyUser', JSON.stringify(res.data));
  };

  return (
    <div className="user-selector-overlay">
      <div className="user-selector-card">
        <div className="selector-header">
          <span className="selector-icon">🏏</span>
          <h1>IPL Fantasy 2026</h1>
          <p>Pick your players. Outscore your friends.</p>
        </div>

        {users.length > 0 && (
          <div className="existing-users">
            <h3>Continue as</h3>
            <div className="user-grid">
              {users.map(user => (
                <button key={user.id} className="user-btn" onClick={() => handleSelect(user)}>
                  <span className="user-btn-avatar">{user.name[0]}</span>
                  <span>{user.name}</span>
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="divider"><span>or</span></div>

        <form onSubmit={handleCreate} className="new-user-form">
          <h3>Join as new player</h3>
          <div className="input-group">
            <input
              type="text"
              value={newName}
              onChange={e => setNewName(e.target.value)}
              placeholder="Enter your name"
              maxLength={20}
            />
            <button type="submit" className="btn-primary">Join</button>
          </div>
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
        <UserSelector />
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
            </Routes>
          </main>
        </div>
      </Router>
    </UserContext.Provider>
  );
}

export default App;
