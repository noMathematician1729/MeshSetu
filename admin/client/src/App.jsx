import { useEffect, useRef, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import Lenis from 'lenis'
import { authToken, getEvents, getNearbyAuthorities, getPublicEvent, getVoice, login, openStream, setStatus, setToken } from './api'
import MarketingApp from './marketing/App.jsx'
import marketingStyles from './marketing/styles.css?inline'
import reactFlowStyles from 'reactflow/dist/style.css?inline'

const priorityRank = { p0Critical: 0, p1High: 1, p2Normal: 2, p3Bulk: 3 }
const sortEvents = events => [...events].sort((a, b) => (priorityRank[a.priority] ?? 9) - (priorityRank[b.priority] ?? 9) || Number(b.triage?.score ?? 0) - Number(a.triage?.score ?? 0) || Number(b.received_at_ms ?? 0) - Number(a.received_at_ms ?? 0))
const statusLabels = { new: 'New', acknowledged: 'Acknowledged', dispatched: 'Dispatched', resolved: 'Resolved' }
const emergencyLabels = {
  general: 'General SOS',
  fire: 'Fire Emergency',
  crime: 'Security Alert',
  kidnap: 'Threat to Life',
  medical: 'Medical Emergency',
  natural_disaster: 'Disaster Alert'
}
const emergencyType = event => emergencyLabels[event?.hazards?.[0]] || emergencyLabels[event?.incident_type] || event?.incident_type || 'Emergency SOS'
const authorityContactsFor = event => {
  const type = event?.triage?.emergency_type || event?.hazards?.[0] || event?.incident_type || 'general'
  const authorities = {
    fire: { name: 'Local Fire & Rescue', role: 'Fire-response dispatch' },
    crime: { name: 'Local Police Command', role: 'Security & tactical dispatch' },
    kidnap: { name: 'Local Police & Special Units', role: 'Threat-to-life response' },
    medical: { name: 'Local Emergency Medical Services', role: 'Ambulance & trauma dispatch' },
    natural_disaster: { name: 'Disaster Management Authority', role: 'Evacuation & relief dispatch' },
    general: { name: 'Local Emergency Response', role: 'General classification & dispatch' },
  }
  return { type, authority: authorities[type] || authorities.general }
}
const controlRoomPath = '/control-room'
const formatTimestamp = value => {
  const date = Number(value) ? new Date(Number(value)) : null
  return date && !Number.isNaN(date.valueOf())
    ? new Intl.DateTimeFormat(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' }).format(date)
    : '—'
}
const mapUrlFor = (latitude, longitude) => {
  if (latitude == null || longitude == null || latitude === '' || longitude === '') return null
  const lat = Number(latitude)
  const lon = Number(longitude)
  if (!Number.isFinite(lat) || !Number.isFinite(lon) || Math.abs(lat) > 90 || Math.abs(lon) > 180) return null
  const span = 0.012
  return `https://www.openstreetmap.org/export/embed.html?bbox=${lon - span}%2C${lat - span}%2C${lon + span}%2C${lat + span}&layer=mapnik&marker=${lat}%2C${lon}`
}
const isolatedMarketingStyles = marketingStyles
  .replace(/:root/g, ':host')
  .replace(/\bhtml\b/g, '.marketing-root')
  .replace(/\bbody\b/g, '.marketing-root')
const isolatedReactFlowStyles = reactFlowStyles
  .replace(/:root/g, ':host')
  .replace(/\bhtml\b/g, '.marketing-root')
  .replace(/\bbody\b/g, '.marketing-root')

function Login({ onLogin }) {
  const [email, setEmail] = useState('operator@meshsetu.local')
  const [password, setPassword] = useState('meshsetu-demo')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async e => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(email, password)
      onLogin()
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="login-shell">
      <div className="login-card">
        <div className="brand">
          <span className="brand-dot" /> MESHSETU
        </div>
        <span className="eyebrow">AUTHORITY ACCESS / LOCAL DISASTER DESK</span>
        <h1 className="login-heading">
          Operator<br />
          <em>sign in.</em>
        </h1>
        <form onSubmit={submit}>
          <label>
            Operator Identity
            <input
              value={email}
              onChange={e => setEmail(e.target.value)}
              type="email"
              placeholder="operator@meshsetu.local"
              required
            />
          </label>
          <label>
            Access Key
            <input
              value={password}
              onChange={e => setPassword(e.target.value)}
              type="password"
              placeholder="••••••••••••"
              required
            />
          </label>
          {error && <div className="notice error-notice">! {error}</div>}
          <button className="btn-primary" disabled={loading}>
            {loading ? 'Authenticating…' : 'Enter control room ↗'}
          </button>
        </form>
        <div className="login-foot">
          <span>Local server</span>
          <span>Zero internet required</span>
        </div>
      </div>
    </main>
  )
}

function Badge({ children, tone = '' }) {
  return <span className={`badge ${tone}`}>{children}</span>
}

function MarketingPage() {
  const hostRef = useRef(null)
  useEffect(() => {
    const host = hostRef.current
    if (!host) return
    const shadow = host.shadowRoot ?? host.attachShadow({ mode: 'open' })
    shadow.innerHTML = ''
    const style = document.createElement('style')
    style.textContent = `${isolatedMarketingStyles}\n${isolatedReactFlowStyles}`
    const mount = document.createElement('div')
    shadow.append(style, mount)
    const root = createRoot(mount)
    root.render(<div className="marketing-root"><MarketingApp /></div>)
    return () => root.unmount()
  }, [])
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return undefined

    const lenis = new Lenis({
      duration: 1.8,
      smoothWheel: true,
      wheelMultiplier: 0.72,
      touchMultiplier: 1.15,
    })
    const update = time => lenis.raf(time * 1000)

    lenis.on('scroll', ScrollTrigger.update)
    gsap.ticker.add(update)
    gsap.ticker.lagSmoothing(0)

    return () => {
      gsap.ticker.remove(update)
      lenis.destroy()
    }
  }, [])
  return <div className="marketing-shell"><div ref={hostRef} /></div>
}

function ControlRoomApp() {
  const [signedIn, setSignedIn] = useState(Boolean(authToken()))
  return signedIn ? (
    <ControlRoom onLogout={() => { setToken(''); setSignedIn(false) }} />
  ) : (
    <Login onLogin={() => setSignedIn(true)} />
  )
}

function PublicIncidentPage({ eventId }) {
  const [event, setEvent] = useState(null)
  const [error, setError] = useState('')
  useEffect(() => {
    getPublicEvent(eventId).then(setEvent).catch(err => setError(err.message))
  }, [eventId])

  if (error) {
    return (
      <main className="public-incident">
        <span className="eyebrow">MESHSETU / SOS DETAIL</span>
        <h1>Incident unavailable</h1>
        <p>{error}</p>
      </main>
    )
  }
  if (!event) {
    return (
      <main className="public-incident">
        <span className="eyebrow">MESHSETU / SOS DETAIL</span>
        <h1>Loading emergency details…</h1>
      </main>
    )
  }
  const coordinates = event.latitude != null && event.longitude != null
    ? `${Number(event.latitude).toFixed(5)}, ${Number(event.longitude).toFixed(5)}`
    : 'Unavailable'

  return (
    <main className="public-incident">
      <header className="public-header">
        <div>
          <span className="crumb">MESHSETU <b>/</b> LIVE SOS</span>
          <h2>{emergencyType(event)}</h2>
        </div>
        <Badge tone={event.status === 'resolved' ? '' : 'critical'}>{event.status || 'new'}</Badge>
      </header>
      <section className="public-incident-card">
        <span className="eyebrow">AUTHENTICATED RELAY / {event.event_id}</span>
        <div className="transcript-box">
          <p className="public-transcript">“{event.transcript || 'No transcript attached to this SOS.'}”</p>
        </div>
        <div className="facts-grid">
          <Fact label="Emergency type" value={emergencyType(event)} />
          <Fact label="Reporter" value={event.reporter_name || event.reporter_uid || 'Unavailable'} />
          <Fact label="Phone" value={event.reporter_phone || 'Unavailable'} />
          <Fact label="Priority" value={event.priority || 'Unavailable'} />
          <Fact label="Zone" value={event.zone || 'Unavailable'} />
          <Fact label="Location" value={coordinates} />
          <Fact label="Relay hops" value={event.hops ?? 'Unavailable'} />
          <Fact label="Received" value={formatTimestamp(event.received_at_ms || event.created_at_ms)} />
          <Fact label="Response status" value={event.status || 'new'} />
          <Fact label="Blood group" value={event.reporter_blood_group || 'Unavailable'} />
          <Fact label="Emergency contact" value={event.reporter_primary_contact || 'Unavailable'} />
        </div>
        <IncidentMap latitude={event.latitude} longitude={event.longitude} />
        <p className="public-note">This is an authenticated SOS transmission linked from local BLE disaster broadcast.</p>
      </section>
    </main>
  )
}

function App() {
  const path = window.location.pathname
  if (path.startsWith('/sos/')) return <PublicIncidentPage eventId={decodeURIComponent(path.slice('/sos/'.length))} />
  return path.startsWith(controlRoomPath) ? <ControlRoomApp /> : <MarketingPage />
}

function ControlRoom({ onLogout }) {
  const [events, setEvents] = useState([])
  const [selectedId, setSelectedId] = useState('')
  const [connection, setConnection] = useState('connecting')
  const [error, setError] = useState('')
  const [filter, setFilter] = useState('all')
  const [voiceUrl, setVoiceUrl] = useState('')
  const [alertQueue, setAlertQueue] = useState([])

  const dismissAlert = () => setAlertQueue(q => q.slice(1))
  const load = () =>
    getEvents()
      .then(next => {
        setEvents(next.sort((a, b) => (priorityRank[a.priority] ?? 9) - (priorityRank[b.priority] ?? 9)))
        setError('')
      })
      .catch(err => setError(err.message))

  useEffect(() => {
    load()
    const socket = openStream(message => {
      if (message.type === 'snapshot') {
        setEvents(message.data.sort((a, b) => (priorityRank[a.priority] ?? 9) - (priorityRank[b.priority] ?? 9)))
      }
      if (message.type === 'incident' || message.type === 'voice' || message.type === 'event') {
        setEvents(current => {
          const next = new Map(current.map(e => [e.event_id, e]))
          const isNew = !next.has(message.data.event_id)
          next.set(message.data.event_id, { ...next.get(message.data.event_id), ...message.data })
          if (isNew && (message.data.priority === 'p0Critical' || message.data.incident_type === 'ceal_compact_sos')) {
            setAlertQueue(q => [...q, message.data])
            try {
              new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1rZ2loamZnanJ0c3Z7hImLjY6Sk5eYm5ydoKGkpaipq62vsLK0tre5u72+wMLExcfJysvNz9DR09TV19jZ29ze3+Dh4+Tl5ufp6uvs7e7v8PHy8/T19vf4+fr7/P3+').play().catch(() => {})
            } catch {}
          }
          return [...next.values()].sort((a, b) => (priorityRank[a.priority] ?? 9) - (priorityRank[b.priority] ?? 9))
        })
      }
    }, setConnection)
    return () => socket.close()
  }, [])

  useEffect(() => {
    setAlertQueue(current =>
      current.map(alert => {
        const update = events.find(event => event.event_id === alert.event_id)
        return update ? { ...alert, ...update } : alert
      })
    )
  }, [events])

  const visible = sortEvents(events.filter(e => filter === 'all' || e.status === filter))
  const selected = visible.find(e => e.event_id === selectedId) || visible[0]
  const critical = events.filter(e => e.priority === 'p0Critical' && e.status !== 'resolved').length
  const verified = events.filter(e => e.decrypt_status === 'verified').length
  const openCount = events.filter(e => e.status !== 'resolved').length

  const update = async status => {
    try {
      const next = await setStatus(selected.event_id, status)
      setEvents(current => current.map(e => (e.event_id === next.event_id ? { ...e, ...next } : e)))
    } catch (err) {
      setError(err.message)
    }
  }

  const play = async () => {
    try {
      setVoiceUrl(await getVoice(selected.event_id))
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="app-shell">
      {alertQueue.length > 0 && (
        <SosAlertPopup
          alert={alertQueue[0]}
          onDismiss={dismissAlert}
          onSelect={() => {
            setSelectedId(alertQueue[0].event_id)
            dismissAlert()
          }}
        />
      )}

      {/* Top Floating Editorial Nav */}
      <header className="top-nav">
        <div className="nav-brand-group">
          <div className="brand">
            <span className="brand-dot" /> MESHSETU
          </div>
          <span className="nav-sub">CONTROL ROOM <b>/</b> EMERGENCY MATRIX</span>
        </div>

        <div className="nav-telemetry">
          <Badge tone={connection === 'live' ? 'live' : 'warn'}>
            ● {connection === 'live' ? 'LIVE SYNC' : connection.toUpperCase()}
          </Badge>
          <span className="telemetry-item">DEMO01 NAMESPACE</span>
          <span className="telemetry-item">BLUETOOTH LE OVERLAY</span>
        </div>

        <div className="nav-actions">
          <button className="btn-ghost-cta" onClick={load}>
            ↻ Sync stream ↗
          </button>
          <button className="btn-outlined" onClick={onLogout}>
            Sign out ↗
          </button>
        </div>
      </header>

      <main className="main-content">
        {/* Page Typographic Statement */}
        <section className="hero-statement">
          <div className="hero-text-block">
            <span className="eyebrow">LOCAL RESPONSE INFRASTRUCTURE · OFFLINE RELAY</span>
            <h1 className="hero-headline">
              Situation <em>room.</em>
            </h1>
          </div>
        </section>

        {/* High-Contrast Editorial Metrics Strip */}
        <section className="metrics-strip">
          <Metric label="Active queue" value={String(openCount).padStart(2, '0')} note="unresolved incidents" />
          <Metric label="Critical priority" value={String(critical).padStart(2, '0')} tone={critical > 0 ? 'red' : ''} note="immediate threat to life" />
          <Metric label="Verified packets" value={String(verified).padStart(2, '0')} note="AEAD encrypted & valid" />
          <Metric label="Transport state" value={connection === 'live' ? 'ONLINE' : 'SYNCING'} tone="light" note="local gateway linked" />
        </section>

        {error && (
          <div className="notice error-banner">
            <span>! {error}</span>
            <button className="btn-ghost-cta" onClick={load}>Retry ↗</button>
          </div>
        )}

        {/* 2-Column Asymmetric Operations Console */}
        <div className="console-grid">
          {/* Incident Queue */}
          <section className="panel queue-panel">
            <div className="panel-header">
              <div>
                <span className="eyebrow">INCIDENT STREAM / {String(visible.length).padStart(2, '0')}</span>
                <h2 className="panel-title">Response Queue</h2>
              </div>
              <div className="filter-pills">
                {['all', 'new', 'acknowledged', 'dispatched', 'resolved'].map(key => (
                  <button
                    key={key}
                    className={`filter-pill ${filter === key ? 'active' : ''}`}
                    onClick={() => setFilter(key)}
                  >
                    {key === 'all' ? 'All' : statusLabels[key] || key}
                  </button>
                ))}
              </div>
            </div>

            <div className="incident-list">
              {visible.length ? (
                visible.map(event => {
                  const isSelected = selected?.event_id === event.event_id
                  const isP0 = event.priority === 'p0Critical'
                  return (
                    <button
                      className={`incident-card ${isSelected ? 'selected' : ''} ${isP0 ? 'is-critical' : ''}`}
                      key={event.event_id}
                      onClick={() => setSelectedId(event.event_id)}
                    >
                      <div className="incident-card-top">
                        <div className="incident-priority-wrap">
                          <span className={`priority-tag ${event.priority}`}>
                            {isP0 ? 'P0' : event.priority?.replace('p', 'P').replace('High', '1').replace('Normal', '2').replace('Bulk', '3')}
                          </span>
                          <strong className="incident-title">{emergencyType(event)}</strong>
                        </div>
                        <Badge tone={event.status === 'new' ? 'critical' : event.status === 'resolved' ? '' : 'live'}>
                          {statusLabels[event.status] || event.status}
                        </Badge>
                      </div>

                      <p className="incident-snippet">
                        {event.transcript ? `“${event.transcript}”` : 'No voice transcript recorded with signal.'}
                      </p>

                      <div className="incident-meta-row">
                        <span>{formatTimestamp(event.received_at_ms || event.created_at_ms)}</span>
                        <span>{event.zone || 'Zone unknown'}</span>
                        <span>{event.hops ?? 0} hops</span>
                      </div>
                    </button>
                  )
                })
              ) : (
                <div className="empty-state">
                  <p>No incidents match the active filter.</p>
                </div>
              )}
            </div>
          </section>

          {/* Incident Telemetry & Action Desk */}
          <Detail
            event={selected}
            onStatus={update}
            onPlay={play}
            voiceUrl={voiceUrl}
          />
        </div>

        {/* Minimal Editorial Footer */}
        <footer className="page-footer">
          <div className="footer-left">
            <span>MESHSETU / OFFLINE-FIRST DISASTER RESPONSE</span>
            <span className="footer-sub">APPLICATION-LAYER BLE MESH OVERLAY · PROTOCOL VERIFIED</span>
          </div>
          <div className="footer-right">
            <span>HUMAN DISPATCH AUTHORITY FINAL</span>
          </div>
        </footer>
      </main>
    </div>
  )
}

function Metric({ label, value, note, tone = '' }) {
  return (
    <div className={`metric-cell ${tone}`}>
      <span className="metric-label">{label}</span>
      <strong className="metric-value">{value}</strong>
      <small className="metric-note">— {note}</small>
    </div>
  )
}

function Detail({ event, onStatus, onPlay, voiceUrl }) {
  if (!event) {
    return (
      <div className="panel detail-panel empty-detail">
        <span className="eyebrow">INCIDENT TELEMETRY</span>
        <p>Select an emergency signal from the queue to inspect authenticated mesh relay telemetry.</p>
      </div>
    )
  }

  const isCritical = event.priority === 'p0Critical'

  return (
    <section className={`panel detail-panel ${isCritical ? 'featured-card' : ''}`}>
      <div className="panel-header">
        <div>
          <span className="eyebrow">AUTHENTICATED RELAY OBJECT / {event.event_id}</span>
          <div className="detail-headline-row">
            <h2 className="panel-title detail-main-title">{emergencyType(event)}</h2>
            <span className="detail-connective">
              <em>via</em> {event.zone || 'Mesh'} · {event.hops ?? 0} hops
            </span>
          </div>
        </div>
        <Badge tone={event.decrypt_status === 'verified' ? 'live' : 'warn'}>
          {event.decrypt_status === 'verified' ? '● VERIFIED AEAD' : event.decrypt_status || 'UNKNOWN'}
        </Badge>
      </div>

      {/* Decrypted Signal Transcript */}
      <div className="transcript-panel">
        <span className="eyebrow">DECRYPTED SIGNAL TRANSCRIPT</span>
        <p className="transcript-text">
          “{event.transcript || 'No voice transcript attached to this emergency signal.'}”
        </p>
      </div>

      {/* Core Facts Matrix */}
      <div className="facts-grid">
        <Fact
          label="Reporter"
          value={event.reporter_name ? `${event.reporter_name}${event.reporter_phone ? ` (${event.reporter_phone})` : ''}` : 'Unavailable'}
        />
        <Fact label="Emergency contact" value={event.reporter_primary_contact || 'Unavailable'} />
        <Fact label="Blood group" value={event.reporter_blood_group || 'Unavailable'} />
        <Fact label="Timestamp" value={formatTimestamp(event.received_at_ms || event.created_at_ms)} />
        <Fact label="Relay hops" value={`${event.hops ?? 0} hops`} />
        <Fact label="Origin latency" value={event.relay_latency_ms ? `${event.relay_latency_ms} ms` : '—'} />
        <Fact label="Packet SHA-256" value={event.packet_sha256 ? `${event.packet_sha256.slice(0, 16)}…` : '—'} />
        <Fact
          label="Triage rating"
          value={event.triage?.score != null ? `${event.triage.score}/100 score` : 'Pending review'}
        />
      </div>

      {/* Live Map Embed */}
      <IncidentMap latitude={event.latitude} longitude={event.longitude} />

      {/* Local Authority Contacts */}
      <AuthorityContacts event={event} />

      {/* Audio Evidence */}
      {event.audio_state === 'complete' && (
        <div className="audio-section">
          <span className="eyebrow">VERIFIED VOICE RECORDING</span>
          <div className="audio-player-row">
            <button className="btn-ghost-cta audio-play-btn" onClick={onPlay}>
              ▶ Play voice transmission ↗
            </button>
            {voiceUrl && <audio controls src={voiceUrl} autoPlay className="voice-audio-element" />}
          </div>
        </div>
      )}

      {/* Operator Action State Controller */}
      <div className="operator-action-section">
        <span className="eyebrow">OPERATOR RESPONSE STATE</span>
        <div className="state-buttons-row">
          {Object.entries(statusLabels).map(([statusKey, label]) => (
            <button
              key={statusKey}
              className={`status-btn ${event.status === statusKey ? 'active' : ''}`}
              onClick={() => onStatus(statusKey)}
            >
              {label}
            </button>
          ))}
        </div>
        {event.triage?.route?.instruction && (
          <p className="triage-instruction">
            Route instruction: {event.triage.route.instruction}
          </p>
        )}
      </div>

      <div className="detail-footer">
        <span>⌁ AUTHENTICATED MESH RELAY OBJECT</span>
        <span>Human operator dispatch remains final ↗</span>
      </div>
    </section>
  )
}

function Fact({ label, value }) {
  return (
    <div className="fact-item">
      <span className="fact-label">{label}</span>
      <b className="fact-value">{value}</b>
    </div>
  )
}

function IncidentMap({ latitude, longitude }) {
  const mapUrl = mapUrlFor(latitude, longitude)
  if (!mapUrl) return null
  const latNum = Number(latitude)
  const lonNum = Number(longitude)

  return (
    <div className="incident-map-wrapper">
      <div className="incident-map-header">
        <span className="eyebrow">REPORTED GPS COORDINATES</span>
        <div className="map-links">
          <span className="coord-value">{latNum.toFixed(5)}, {lonNum.toFixed(5)}</span>
          <a
            href={`https://www.openstreetmap.org/?mlat=${latNum}&mlon=${lonNum}#map=16/${latNum}/${lonNum}`}
            target="_blank"
            rel="noreferrer"
            className="btn-ghost-cta map-ext-link"
          >
            Open full map ↗
          </a>
        </div>
      </div>
      <iframe title="Reported SOS location" src={mapUrl} loading="lazy" referrerPolicy="no-referrer" />
    </div>
  )
}

function AuthorityContacts({ event }) {
  const { type, authority } = authorityContactsFor(event)
  const latitude = Number(event.latitude)
  const longitude = Number(event.longitude)
  const hasLocation = Number.isFinite(latitude) && Number.isFinite(longitude)
  const [state, setState] = useState({ loading: hasLocation, authorities: [], error: '' })

  useEffect(() => {
    if (!hasLocation) {
      setState({ loading: false, authorities: [], error: 'No GPS location attached to this SOS.' })
      return
    }
    let active = true
    setState({ loading: true, authorities: [], error: '' })
    getNearbyAuthorities({ latitude, longitude, type })
      .then(authorities => {
        if (active) setState({ loading: false, authorities, error: '' })
      })
      .catch(error => {
        if (active) setState({ loading: false, authorities: [], error: error.message })
      })
    return () => {
      active = false
    }
  }, [event.event_id, latitude, longitude, type])

  return (
    <div className="authority-section">
      <div className="authority-header">
        <div>
          <span className="eyebrow">NEAREST DISPATCH ENTITY</span>
          <h4 className="authority-title">{authority.name}</h4>
        </div>
        <span className="authority-role-pill">{authority.role}</span>
      </div>

      {state.loading && <div className="authority-status">Scanning nearby registered emergency contacts…</div>}
      {state.error && <div className="authority-status">{state.error}</div>}
      {!state.loading && !state.error && !state.authorities.length && (
        <div className="authority-status">No nearby facility with a published telephone was detected.</div>
      )}

      {state.authorities.length > 0 && (
        <div className="authority-grid">
          {state.authorities.map(item => (
            <div className="authority-card" key={`${item.name}-${item.phone}`}>
              <div className="authority-info">
                <strong className="authority-unit-name">{item.name}</strong>
                <small className="authority-distance">
                  {item.address || 'Address not published'} · {(item.distance_m / 1000).toFixed(item.distance_m < 10_000 ? 1 : 0)} km away
                </small>
              </div>
              <a href={`tel:${item.phone.replace(/[^\d+]/g, '')}`} className="btn-call">
                {item.phone} ↗
              </a>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function SosAlertPopup({ alert, onDismiss, onSelect }) {
  useEffect(() => {
    const timer = setTimeout(onDismiss, 30000)
    return () => clearTimeout(timer)
  }, [alert?.event_id])

  const isCeal = alert.decrypt_status === 'ceal-uid-only'
  const reporter = alert.reporter_name || (isCeal ? `UID ${alert.reporter_uid || 'unknown'}` : 'Unknown Sender')

  return (
    <div className="sos-alert-overlay" onClick={onSelect}>
      <div className="sos-alert-card" onClick={e => e.stopPropagation()}>
        <div className="sos-alert-badge">
          <span className="brand-dot" /> CRITICAL SOS TRANSMISSION
        </div>
        <h2 className="sos-alert-headline">{emergencyType(alert)}</h2>
        <p className="sos-alert-reporter">{reporter}{alert.reporter_phone ? ` · ${alert.reporter_phone}` : ''}</p>

        {alert.transcript && (
          <div className="sos-alert-quote">
            <p>“{alert.transcript}”</p>
          </div>
        )}

        <div className="sos-alert-meta">
          <span>Received {formatTimestamp(alert.received_at_ms || alert.created_at_ms)}</span>
          {alert.latitude != null && (
            <span>GPS: {Number(alert.latitude).toFixed(4)}, {Number(alert.longitude).toFixed(4)}</span>
          )}
        </div>

        <div className="sos-alert-actions">
          <button className="btn-alert-inspect" onClick={onSelect}>
            Inspect incident ↗
          </button>
          <button className="btn-alert-dismiss" onClick={onDismiss}>
            Dismiss
          </button>
        </div>
        <small className="sos-alert-timer">Auto-dismisses in 30s · Click anywhere to view</small>
      </div>
    </div>
  )
}

export default App
