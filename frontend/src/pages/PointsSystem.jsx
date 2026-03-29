function PointsSystem() {
  return (
    <div className="points-system-page">
      <div className="page-header">
        <h1>📋 Points System</h1>
        <p className="page-subtitle">Fantasy points breakdown for IPL 2026</p>
      </div>

      <div className="points-sections">
        {/* Batting */}
        <div className="points-category">
          <div className="category-header batting">
            <span className="category-icon">🏏</span>
            <h2>Batting</h2>
          </div>
          <div className="points-rules">
            <div className="rule-row">
              <span className="rule-label">Run scored</span>
              <span className="rule-value positive">+1</span>
              <span className="rule-note">per run</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Boundary bonus (4s)</span>
              <span className="rule-value positive">+1</span>
              <span className="rule-note">per four</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Six bonus (6s)</span>
              <span className="rule-value positive">+2</span>
              <span className="rule-note">per six</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">30 runs milestone</span>
              <span className="rule-value positive">+4</span>
              <span className="rule-note">bonus</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Half-century (50 runs)</span>
              <span className="rule-value positive">+8</span>
              <span className="rule-note">bonus</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Century (100 runs)</span>
              <span className="rule-value positive">+16</span>
              <span className="rule-note">bonus</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Duck (out at 0)</span>
              <span className="rule-value negative">−2</span>
              <span className="rule-note">BAT / WK / AR only</span>
            </div>
          </div>
        </div>

        {/* Bowling */}
        <div className="points-category">
          <div className="category-header bowling">
            <span className="category-icon">🎳</span>
            <h2>Bowling</h2>
          </div>
          <div className="points-rules">
            <div className="rule-row">
              <span className="rule-label">Wicket taken</span>
              <span className="rule-value positive">+25</span>
              <span className="rule-note">per wicket</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">LBW / Bowled bonus</span>
              <span className="rule-value positive">+8</span>
              <span className="rule-note">per dismissal</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">3-wicket haul</span>
              <span className="rule-value positive">+4</span>
              <span className="rule-note">bonus</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">4-wicket haul</span>
              <span className="rule-value positive">+8</span>
              <span className="rule-note">bonus (stacks with 3W)</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">5-wicket haul</span>
              <span className="rule-value positive">+16</span>
              <span className="rule-note">bonus (stacks)</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Maiden over</span>
              <span className="rule-value positive">+12</span>
              <span className="rule-note">per maiden</span>
            </div>
          </div>
        </div>

        {/* Fielding */}
        <div className="points-category">
          <div className="category-header fielding">
            <span className="category-icon">🧤</span>
            <h2>Fielding</h2>
          </div>
          <div className="points-rules">
            <div className="rule-row">
              <span className="rule-label">Catch</span>
              <span className="rule-value positive">+8</span>
              <span className="rule-note">per catch</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Stumping</span>
              <span className="rule-value positive">+12</span>
              <span className="rule-note">per stumping</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Direct run out</span>
              <span className="rule-value positive">+12</span>
              <span className="rule-note">per run out</span>
            </div>
            <div className="rule-row">
              <span className="rule-label">Indirect run out</span>
              <span className="rule-value positive">+6</span>
              <span className="rule-note">per run out</span>
            </div>
          </div>
        </div>

        {/* Multipliers */}
        <div className="points-category">
          <div className="category-header multipliers">
            <span className="category-icon">⚡</span>
            <h2>Captain & Vice Captain</h2>
          </div>
          <div className="points-rules">
            <div className="rule-row highlight-captain">
              <span className="rule-label">Captain</span>
              <span className="rule-value positive">×2</span>
              <span className="rule-note">all points doubled</span>
            </div>
            <div className="rule-row highlight-vc">
              <span className="rule-label">Vice Captain</span>
              <span className="rule-value positive">×1.5</span>
              <span className="rule-note">all points × 1.5</span>
            </div>
          </div>
        </div>

        {/* Notes */}
        <div className="points-notes">
          <h3>📝 Notes</h3>
          <ul>
            <li>Milestone bonuses (30, 50, 100 runs) <strong>do not stack</strong> — only the highest achieved bonus applies.</li>
            <li>Wicket bonuses (3W, 4W, 5W) <strong>do stack</strong> — a 5-wicket haul earns 4 + 8 + 16 = 28 bonus points.</li>
            <li>Duck penalty only applies to Batsmen, Wicket-keepers, and All-rounders — not pure Bowlers.</li>
            <li>Captain and Vice Captain multipliers apply to the <strong>total base points</strong> (batting + bowling + fielding).</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default PointsSystem;
