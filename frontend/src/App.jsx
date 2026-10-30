import React, { useState, useEffect } from 'react';
import './App.css';

export default function App() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('Dashboard');

  // Interactive sample tasks for the dashboard mockup
  const [tasks, setTasks] = useState([
    { id: 1, text: 'Design landing page', priority: 'High', completed: false },
    { id: 2, text: 'Review pull requests', priority: 'Medium', completed: false },
    { id: 3, text: 'Plan next sprint', priority: 'Low', completed: false },
    { id: 4, text: 'Update documentation', priority: 'Low', completed: true },
  ]);

  // Handle scroll detection for sticky navbar styling
  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 25);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Toggle task completion and dynamically update stats
  const toggleTask = (id) => {
    setTasks(prevTasks =>
      prevTasks.map(task =>
        task.id === id ? { ...task, completed: !task.completed } : task
      )
    );
  };

  const completedCount = 17 + tasks.filter(t => t.completed).length;
  const inProgressCount = Math.max(0, 6 - tasks.filter(t => t.completed).length);

  const scrollTo = (id) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
      setMobileMenuOpen(false);
    }
  };

  return (
    <div className="taskflow-app">
      {/* Dynamic Background Glowing Orbs & Atmosphere */}
      <div className="cosmic-glow-orb glow-top-right" aria-hidden="true"></div>
      <div className="cosmic-glow-orb glow-bottom-left" aria-hidden="true"></div>
      <div className="cosmic-glow-orb glow-center" aria-hidden="true"></div>

      {/* Floating 3D Geometric Cubes */}
      <div className="floating-cube cube-left" aria-hidden="true">
        <div className="cube-inner"></div>
      </div>
      <div className="floating-cube cube-right" aria-hidden="true">
        <div className="cube-inner"></div>
      </div>
      <div className="floating-cube cube-small" aria-hidden="true">
        <div className="cube-inner"></div>
      </div>

      {/* Navigation Bar */}
      <nav className={`navbar ${isScrolled ? 'scrolled' : ''}`}>
        <div className="nav-container">
          <div className="brand" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })} role="button" tabIndex={0}>
            <div className="logo-sparkle">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2L14.7 9.3L22 12L14.7 14.7L12 22L9.3 14.7L2 12L9.3 9.3L12 2Z"/>
              </svg>
            </div>
            <span className="brand-name">TaskFlow</span>
          </div>

          <div className="nav-links desktop-only">
            <button className="nav-link active" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>Home</button>
            <button className="nav-link" onClick={() => scrollTo('features')}>Features</button>
            <button className="nav-link" onClick={() => scrollTo('how-it-works')}>How It Works</button>
            <button className="nav-link" onClick={() => scrollTo('about')}>About</button>
          </div>

          <div className="nav-actions desktop-only">
            <button className="btn-glow-pill" onClick={() => scrollTo('cta')}>Get Started</button>
          </div>

          {/* Mobile Hamburger Toggle */}
          <button 
            className="mobile-toggle"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle navigation menu"
          >
            <span className={`bar ${mobileMenuOpen ? 'open-1' : ''}`}></span>
            <span className={`bar ${mobileMenuOpen ? 'open-2' : ''}`}></span>
            <span className={`bar ${mobileMenuOpen ? 'open-3' : ''}`}></span>
          </button>
        </div>

        {/* Mobile Dropdown Menu */}
        {mobileMenuOpen && (
          <div className="mobile-dropdown">
            <button onClick={() => { window.scrollTo({ top: 0, behavior: 'smooth' }); setMobileMenuOpen(false); }}>Home</button>
            <button onClick={() => scrollTo('features')}>Features</button>
            <button onClick={() => scrollTo('how-it-works')}>How It Works</button>
            <button onClick={() => scrollTo('about')}>About</button>
            <button className="btn-glow-pill w-full" onClick={() => scrollTo('cta')}>Get Started</button>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <header className="hero-section">
        <div className="hero-container">
          {/* Left Column: Hero Content */}
          <div className="hero-content">
            <div className="badge-pill">
              <span className="badge-sparkle">✦</span> ORGANIZE • FOCUS • ACHIEVE
            </div>
            <h1 className="hero-title">
              Turn Your Ideas<br />
              Into <span className="gradient-text">Real Progress</span>
            </h1>
            <p className="hero-subtitle">
              TaskFlow is a modern productivity platform that helps you plan, track, and achieve your goals — beautifully.
            </p>
            <div className="hero-cta-group">
              <button className="btn-primary" onClick={() => scrollTo('features')}>
                <span>Get Started Free</span>
                <svg className="arrow-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <path d="M5 12h14M12 5l7 7-7 7"/>
                </svg>
              </button>
              <button className="btn-glass" onClick={() => scrollTo('how-it-works')}>
                <span className="play-icon">▶</span>
                <span>Watch Demo</span>
              </button>
            </div>

            {/* Social Proof */}
            <div className="social-proof">
              <div className="avatar-group">
                <div className="avatar av-1">👨‍💻</div>
                <div className="avatar av-2">👩‍🎨</div>
                <div className="avatar av-3">👨‍🚀</div>
                <div className="avatar av-4">👩‍💻</div>
              </div>
              <div className="proof-text">
                <div className="stars">★★★★★</div>
                <span className="user-count">Trusted by 10,000+ users</span>
              </div>
            </div>
          </div>

          {/* Right Column: 3D Floating Dashboard Mockup */}
          <div className="hero-visual">
            <div className="visual-orbit-glow" aria-hidden="true"></div>
            
            <div className="dashboard-mockup">
              {/* Mockup Sidebar */}
              <aside className="mockup-sidebar">
                <div className="sidebar-brand">
                  <span className="sidebar-sparkle">✦</span> TaskFlow
                </div>
                <div className="sidebar-menu">
                  {['Dashboard', 'My Tasks', 'Calendar', 'Analytics', 'Settings'].map((item) => (
                    <button
                      key={item}
                      className={`sidebar-item ${activeTab === item ? 'active' : ''}`}
                      onClick={() => setActiveTab(item)}
                    >
                      <span className="item-icon">
                        {item === 'Dashboard' && '📊'}
                        {item === 'My Tasks' && '📝'}
                        {item === 'Calendar' && '📅'}
                        {item === 'Analytics' && '📈'}
                        {item === 'Settings' && '⚙️'}
                      </span>
                      <span>{item}</span>
                    </button>
                  ))}
                </div>
              </aside>

              {/* Mockup Main View */}
              <main className="mockup-main">
                {/* Topbar */}
                <div className="mockup-topbar">
                  <div className="mockup-search">
                    <span className="search-icon">🔍</span>
                    <span>Search tasks...</span>
                  </div>
                  <div className="mockup-profile">
                    <span className="bell-badge">🔔</span>
                    <div className="avatar-small">👩‍💼</div>
                  </div>
                </div>

                {/* Greeting */}
                <div className="mockup-greeting">
                  <h3>Good Morning,</h3>
                  <p>Let's make today productive! 🚀</p>
                </div>

                {/* 3 Metric Stat Cards */}
                <div className="mockup-stats">
                  <div className="stat-card">
                    <div className="stat-icon-wrapper purple">
                      <span>⚡</span>
                    </div>
                    <div className="stat-data">
                      <div className="stat-num">12</div>
                      <div className="stat-label">Tasks Today</div>
                    </div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-icon-wrapper blue">
                      <span>🔄</span>
                    </div>
                    <div className="stat-data">
                      <div className="stat-num">{inProgressCount}</div>
                      <div className="stat-label">In Progress</div>
                    </div>
                  </div>

                  <div className="stat-card">
                    <div className="stat-icon-wrapper green">
                      <span>✓</span>
                    </div>
                    <div className="stat-data">
                      <div className="stat-num">{completedCount}</div>
                      <div className="stat-label">Completed</div>
                    </div>
                  </div>
                </div>

                {/* Lower Grid: Tasks & CSS Bar Chart */}
                <div className="mockup-grid">
                  {/* Today's Tasks */}
                  <div className="mockup-panel tasks-panel">
                    <div className="panel-title">Today's Tasks</div>
                    <div className="panel-task-list">
                      {tasks.map(task => (
                        <div 
                          key={task.id} 
                          className={`task-row ${task.completed ? 'completed' : ''}`}
                          onClick={() => toggleTask(task.id)}
                          role="button"
                          tabIndex={0}
                          title="Click to toggle status"
                        >
                          <div className={`checkbox-circle ${task.completed ? 'checked' : ''}`}>
                            {task.completed && '✓'}
                          </div>
                          <span className="task-name">{task.text}</span>
                          <span className={`priority-tag ${task.priority.toLowerCase()}`}>
                            {task.priority}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Productivity Bar Chart */}
                  <div className="mockup-panel chart-panel">
                    <div className="chart-header">
                      <span className="panel-title">Productivity</span>
                      <span className="chart-filter">This Week ▾</span>
                    </div>
                    <div className="css-bar-chart">
                      {[
                        { day: 'Mon', h: '42%' },
                        { day: 'Tue', h: '60%' },
                        { day: 'Wed', h: '88%' },
                        { day: 'Thu', h: '50%' },
                        { day: 'Fri', h: '96%' },
                        { day: 'Sat', h: '35%' },
                        { day: 'Sun', h: '75%' }
                      ].map((item, idx) => (
                        <div key={idx} className="chart-bar-group">
                          <div className="bar-track">
                            <div className="bar-fill" style={{ height: item.h }}></div>
                          </div>
                          <span className="bar-day">{item.day}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </main>
            </div>
          </div>
        </div>
      </header>

      {/* Features Section */}
      <section id="features" className="features-section">
        <div className="section-header">
          <h2>
            Everything You Need to <span className="gradient-text">Stay Productive</span>
          </h2>
          <p>Powerful features designed to help you work smarter, not harder.</p>
        </div>

        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon icon-purple">⚡</div>
            <h3>Smart Task Management</h3>
            <p>Create, organize, and prioritize tasks with ease using intelligent tags, smart scheduling, and quick gestures.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon icon-blue">📅</div>
            <h3>Beautiful Calendar</h3>
            <p>Get a clear view of your schedule, timeline sprints, and never miss an upcoming milestone or deadline.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon icon-cyan">📊</div>
            <h3>Insights & Analytics</h3>
            <p>Track your daily velocity, study weekly trends, and stay motivated with intuitive visual progress metrics.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon icon-orange">👥</div>
            <h3>Work Anywhere</h3>
            <p>Access your tasks on any device, anywhere, anytime with responsive offline synchronization.</p>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="steps-section">
        <div className="section-header">
          <h2>
            How It <span className="gradient-text">Works</span>
          </h2>
          <p>Get started in seconds and boost your daily productivity.</p>
        </div>

        <div className="steps-container">
          <div className="step-card">
            <div className="step-badge">01</div>
            <h3>Plan Your Day</h3>
            <p>Capture your thoughts, set priority tags, and organize your daily agenda in seconds.</p>
          </div>

          <div className="step-connector" aria-hidden="true"></div>

          <div className="step-card">
            <div className="step-badge">02</div>
            <h3>Track Your Progress</h3>
            <p>Monitor completion milestones in real time with interactive dashboards and visual charts.</p>
          </div>

          <div className="step-connector" aria-hidden="true"></div>

          <div className="step-card">
            <div className="step-badge">03</div>
            <h3>Achieve Your Goals</h3>
            <p>Maintain consistent streaks, celebrate completed sprints, and reach new heights of performance.</p>
          </div>
        </div>
      </section>

      {/* Call to Action Section */}
      <section id="cta" className="cta-section">
        <div className="cta-card">
          <div className="cta-glow" aria-hidden="true"></div>
          <h2>Ready to Make Progress?</h2>
          <p>Join over 10,000+ teams and high achievers streamlining their daily productivity with TaskFlow.</p>
          <button className="btn-primary" onClick={() => scrollTo('features')}>
            <span>Get Started Today</span>
            <svg className="arrow-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
          </button>
          <div className="cta-footnote">Free 14-day trial • No credit card required</div>
        </div>
      </section>

      {/* Footer */}
      <footer id="about" className="footer">
        <div className="footer-container">
          <div className="footer-brand">
            <div className="brand" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
              <div className="logo-sparkle">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2L14.7 9.3L22 12L14.7 14.7L12 22L9.3 14.7L2 12L9.3 9.3L12 2Z"/>
                </svg>
              </div>
              <span className="brand-name">TaskFlow</span>
            </div>
            <p className="footer-tagline">
              The futuristic productivity platform designed for modern thinkers and doers.
            </p>
          </div>

          <div className="footer-links">
            <div className="footer-col">
              <h4>Product</h4>
              <a href="#features">Features</a>
              <a href="#how-it-works">How It Works</a>
              <a href="#cta">Pricing</a>
            </div>
            <div className="footer-col">
              <h4>Company</h4>
              <a href="#about">About</a>
              <a href="#about">Careers</a>
              <a href="#about">Privacy Policy</a>
            </div>
          </div>
        </div>

        <div className="footer-bottom">
          © {new Date().getFullYear()} TaskFlow Inc. All rights reserved.
        </div>
      </footer>
    </div>
  );
}
