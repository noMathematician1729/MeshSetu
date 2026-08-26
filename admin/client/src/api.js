const localBackend = window.location.protocol === 'http:'
  ? `${window.location.protocol}//${window.location.hostname}:8000`
  : 'https://kisha-volcanologic-motherly.ngrok-free.dev'
const base = (import.meta.env.VITE_API_BASE_URL || localBackend).replace(/\/$/, '')
let token = localStorage.getItem('meshsetu_token') || ''
export const authToken = () => token
export function setToken(value) { token = value; value ? localStorage.setItem('meshsetu_token', value) : localStorage.removeItem('meshsetu_token') }
function headers() { return token ? { Authorization: `Bearer ${token}` } : {} }
async function request(path, options = {}) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 30000)
  try {
    const response = await fetch(`${base}${path}`, { ...options, signal: controller.signal, headers: { ...headers(), ...(options.headers || {}) } })
    if (response.status === 401) { setToken(''); throw new Error('Session expired') }
    if (!response.ok) throw new Error((await response.json().catch(() => ({}))).error || `Request failed (${response.status})`)
    return response
  } catch (error) {
    if (error?.name === 'AbortError') throw new Error('Request timed out after 30 seconds. Check the backend and try again.')
    throw error
  } finally {
    clearTimeout(timeout)
  }
}
export async function login(email, password) { const response = await fetch(`${base}/v1/auth/token`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) }); if (!response.ok) throw new Error('Invalid operator credentials'); const data = await response.json(); setToken(data.access_token); return data }
export async function getEvents() { return (await request('/v1/sos')).json() }
export async function getNearbyAuthorities({ latitude, longitude, type }) { return (await request(`/v1/authorities/nearby?latitude=${encodeURIComponent(latitude)}&longitude=${encodeURIComponent(longitude)}&type=${encodeURIComponent(type)}`)).json() }
export async function createAuthorityResponse(eventId, { type, messageText, expiresInSeconds = 300 }) {
  const idempotencyKey = globalThis.crypto?.randomUUID?.() || `${eventId}-${Date.now()}-${Math.random()}`
  return (await request(`/v1/events/${encodeURIComponent(eventId)}/responses`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'idempotency-key': idempotencyKey },
    body: JSON.stringify({ type, message_text: messageText, expires_in_seconds: expiresInSeconds }),
  })).json()
}
export async function getAuthorityResponse(responseId) { return (await request(`/v1/responses/${encodeURIComponent(responseId)}`)).json() }
export async function setStatus(id, status) { return (await request(`/v1/sos/${encodeURIComponent(id)}/status`, { method: 'PATCH', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ status }) })).json() }
export async function getVoice(id) { const response = await request(`/v1/sos/${encodeURIComponent(id)}/voice`); return URL.createObjectURL(await response.blob()) }
export function openStream(onMessage, onState) { const url = new URL(`${base || window.location.origin}/v1/stream`); url.searchParams.set('token', token); url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:'; const socket = new WebSocket(url); socket.onopen = () => onState('live'); socket.onclose = () => onState('offline'); socket.onerror = () => onState('offline'); socket.onmessage = event => { try { onMessage(JSON.parse(event.data)) } catch {} }; return socket }

export async function getPublicEvent(id) { return (await request(`/v1/public/sos/${encodeURIComponent(id)}`)).json() }
