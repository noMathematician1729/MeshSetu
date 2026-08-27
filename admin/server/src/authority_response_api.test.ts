import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest'
import jwt from 'jsonwebtoken'

process.env.NODE_ENV = 'test'
process.env.JWT_SECRET = 'meshsetu-test-jwt'
process.env.MESHSETU_GATEWAY_SECRET = 'meshsetu-test-gateway'
process.env.MESHSETU_ADMIN_EMAIL = 'operator@test.local'
process.env.MESHSETU_ADMIN_PASSWORD = 'test-password'

const { store } = await import('./store.js')
const { server } = await import('./server.js')

let baseUrl = ''
let bearer = ''

const eventRecord = () => ({
  event_id: 'api-event-1',
  object_id: 'api-object-1',
  site_id: 'api-site',
  room_id: 'public',
  priority: 'p0Critical',
  incident_type: 'medical',
  status: 'new',
  origin_ephemeral_id: '123456789',
  created_at_ms: 100,
  expires_at_ms: Date.now() + 600000,
  received_at_ms: Date.now(),
  packet_sha256: 'api-test',
  decrypt_status: 'verified',
})

async function request(path: string, init: RequestInit = {}) {
  const headers = new Headers(init.headers)
  return fetch(`${baseUrl}${path}`, { ...init, headers })
}

async function createResponse(idempotencyKey = 'response-key') {
  return request('/v1/events/api-event-1/responses', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${bearer}`,
      'content-type': 'application/json',
      'idempotency-key': idempotencyKey,
    },
    body: JSON.stringify({
      type: 'SOS_RECEIVED',
      message_text: 'Control room received your SOS.',
      expires_in_seconds: 300,
    }),
  })
}

describe('authority response HTTP lifecycle', () => {
  beforeAll(async () => {
    await new Promise<void>(resolve => server.listen(0, '127.0.0.1', () => resolve()))
    const address = server.address()
    if (!address || typeof address === 'string') throw new Error('test server has no address')
    baseUrl = `http://127.0.0.1:${address.port}`
    const token = jwt.sign({ sub: 'operator@test.local', role: 'operator' }, 'meshsetu-test-jwt')
    bearer = token
  })

  beforeEach(async () => {
    store.memory.clear()
    store.authorityResponses.clear()
    store.authorityIdempotency.clear()
    store.authorityReceipts.clear()
    await store.upsert(eventRecord())
  })

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()))
  })

  it('allows authority-response preflight headers from the local admin client', async () => {
    const preflight = await request('/v1/events/api-event-1/responses', {
      method: 'OPTIONS',
      headers: {
        origin: 'http://localhost:5173',
        'access-control-request-method': 'POST',
        'access-control-request-headers': 'authorization,content-type,idempotency-key',
      },
    })
    expect(preflight.status).toBe(204)
    expect(preflight.headers.get('access-control-allow-origin')).toBe('http://localhost:5173')
    expect(preflight.headers.get('access-control-allow-headers')?.toLowerCase()).toContain('idempotency-key')
  })

  it('creates an idempotent signed response and rejects conflicting replay', async () => {
    const created = await createResponse('same-key')
    expect(created.status).toBe(201)
    const first = await created.json() as { response_id: string; signed_payload_b64: string; replayed: boolean }
    expect(first.signed_payload_b64.length).toBeGreaterThan(0)
    expect(first.replayed).toBe(false)

    const replay = await createResponse('same-key')
    expect(replay.status).toBe(200)
    expect((await replay.json()).response_id).toBe(first.response_id)

    const conflict = await request('/v1/events/api-event-1/responses', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${bearer}`,
        'content-type': 'application/json',
        'idempotency-key': 'same-key',
      },
      body: JSON.stringify({ type: 'SOS_RECEIVED', message_text: 'different text', expires_in_seconds: 300 }),
    })
    expect(conflict.status).toBe(409)
  })

  it('preserves the sender incident namespace in a response record', async () => {
    await store.upsert({ ...eventRecord(), site_id: 'phone-a-local-event' })

    const created = await createResponse('namespace-key')
    expect(created.status).toBe(201)
    const response = await created.json() as { site_id: string }
    expect(response.site_id).toBe('phone-a-local-event')
  })

  it('waits for verified encrypted SOS details before signing a compact-only return', async () => {
    await store.upsert({ ...eventRecord(), decrypt_status: 'ceal-uid-only' })

    const created = await createResponse('compact-only-key')
    expect(created.status).toBe(409)
    expect((await created.json()).error).toContain('verified encrypted SOS')
  })

  it('long-polls a pending command, acknowledges it, and hides it from the next poll', async () => {
    const created = await createResponse('command-key')
    const response = await created.json() as { response_id: string }
    const commands = await request('/v1/gateways/gateway-session/commands?cursor=0&wait_ms=0', {
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway' },
    })
    expect(commands.status).toBe(200)
    const body = await commands.json() as { commands: Array<{ response_id: string }> }
    expect(body.commands.map(command => command.response_id)).toContain(response.response_id)

    const acknowledged = await request(`/v1/gateways/gateway-session/commands/${response.response_id}/received`, {
      method: 'POST',
      headers: {
        'x-meshsetu-gateway-key': 'meshsetu-test-gateway',
        'content-type': 'application/json',
      },
      body: JSON.stringify({ mesh_object_id: '7001' }),
    })
    expect(acknowledged.status).toBe(200)
    expect((await acknowledged.json()).response.state).toBe('MESH_QUEUED')

    const next = await request('/v1/gateways/gateway-session/commands?cursor=0&wait_ms=0', {
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway' },
    })
    expect((await next.json()).commands).toHaveLength(0)
  })

  it('accepts only a receipt matching the response event and destination', async () => {
    const created = await createResponse('receipt-key')
    const response = await created.json() as { response_id: string }

    const wrongSender = await request(`/v1/responses/${response.response_id}/receipts`, {
      method: 'POST',
      headers: {
        'x-meshsetu-gateway-key': 'meshsetu-test-gateway',
        'content-type': 'application/json',
      },
      body: JSON.stringify({ receipt_id: 'wrong', reply_to_event_id: 'api-event-1', sender_ephemeral_id: '999', created_at_ms: 101 }),
    })
    expect(wrongSender.status).toBe(400)

    const accepted = await request(`/v1/responses/${response.response_id}/receipts`, {
      method: 'POST',
      headers: {
        'x-meshsetu-gateway-key': 'meshsetu-test-gateway',
        'content-type': 'application/json',
      },
      body: JSON.stringify({ receipt_id: 'correct', reply_to_event_id: 'api-event-1', sender_ephemeral_id: '123456789', created_at_ms: 101 }),
    })
    expect(accepted.status).toBe(200)
    expect((await accepted.json()).response.state).toBe('RECEIPT_AT_DASHBOARD')
  })

  it('accepts authenticated monotonic mesh progress and rejects false sender delivery', async () => {
    const created = await createResponse('progress-key')
    const response = await created.json() as { response_id: string }

    const unauthenticated = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'FORWARDING', route_mode: 'reverseCache', return_hops: 1, retry_count: 0 }),
    })
    expect(unauthenticated.status).toBe(401)

    const queued = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'MESH_QUEUED', gateway_session_id: 'gateway-session', return_hops: 0, retry_count: 0 }),
    })
    expect(queued.status).toBe(200)
    expect((await queued.json()).response.state).toBe('MESH_QUEUED')

    const forwarding = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'FORWARDING', route_mode: 'reverseCache', return_hops: 1, retry_count: 0 }),
    })
    expect(forwarding.status).toBe(200)
    expect((await forwarding.json()).response.route_mode).toBe('reverseCache')

    const duplicate = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'FORWARDING', route_mode: 'reverseCache', return_hops: 1, retry_count: 0 }),
    })
    expect(duplicate.status).toBe(200)

    const regression = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'MESH_QUEUED' }),
    })
    expect(regression.status).toBe(409)

    const forgedDelivery = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'SENDER_DELIVERED' }),
    })
    expect(forgedDelivery.status).toBe(400)

    const delivered = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'SENDER_DELIVERED', receipt_id: 'progress-receipt', reply_to_event_id: 'api-event-1', sender_ephemeral_id: '123456789' }),
    })
    expect(delivered.status).toBe(200)
    expect((await delivered.json()).response.state).toBe('SENDER_DELIVERED')
  })

  it('persists explicit no-route failure and terminal progress is not reversible', async () => {
    const created = await createResponse('failure-progress-key')
    const response = await created.json() as { response_id: string }
    const failed = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'FAILED', route_mode: 'retry', retry_count: 4, error: 'no_eligible_return_route' }),
    })
    expect(failed.status).toBe(200)
    expect((await failed.json()).response.last_error).toBe('no_eligible_return_route')

    const lateForward = await request(`/v1/responses/${response.response_id}/progress`, {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ state: 'FORWARDING', route_mode: 'retry', retry_count: 5 }),
    })
    expect(lateForward.status).toBe(409)
  })

  it('sends gateway commands with the original mesh event ID after incident convergence', async () => {
    await store.upsert({ ...eventRecord(), return_event_id: 'wire-event-1' })
    const created = await createResponse('converged-event-key')
    const response = await created.json() as { response_id: string; event_id: string; reply_to_event_id: string }
    expect(response.event_id).toBe('api-event-1')
    expect(response.reply_to_event_id).toBe('wire-event-1')

    const commands = await request('/v1/gateways/gateway-session/commands?cursor=0&wait_ms=0', {
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway' },
    })
    const command = (await commands.json() as { commands: Array<{ response_id: string; event_id: string }> }).commands
      .find((item) => item.response_id === response.response_id)
    expect(command?.event_id).toBe('wire-event-1')
  })

  it('paginates commands created in the same millisecond without skipping either response', async () => {
    const createdAtMs = Date.now()
    const makeCommand = (responseId: string) => ({
      response_id: responseId,
      event_id: 'api-event-1',
      site_id: 'api-site',
      response_type: 'SOS_RECEIVED',
      message_text: 'Control room received your SOS.',
      destination_ephemeral_id: '123456789',
      signed_payload: Buffer.from([1, 2, 3]),
      key_id: 'test-key',
      state: 'SIGNED' as const,
      route_mode: null,
      return_hops: 0,
      retry_count: 0,
      created_at_ms: createdAtMs,
      expires_at_ms: createdAtMs + 60_000,
      gateway_session_id: null,
      trace_id: null,
      original_trace_id: null,
    })
    store.authorityResponses.set('same-ms-a', makeCommand('same-ms-a'))
    store.authorityResponses.set('same-ms-b', makeCommand('same-ms-b'))

    const first = await request('/v1/gateways/gateway-session/commands?cursor=0&wait_ms=0&limit=1', {
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway' },
    })
    const firstPage = await first.json() as { cursor: string; commands: Array<{ response_id: string }> }
    expect(firstPage.commands.map(command => command.response_id)).toEqual(['same-ms-a'])
    expect(firstPage.cursor).toBe(`${createdAtMs}:same-ms-a`)

    const firstAcknowledged = await request('/v1/gateways/gateway-session/commands/same-ms-a/received', {
      method: 'POST',
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway', 'content-type': 'application/json' },
      body: JSON.stringify({ mesh_object_id: '7001' }),
    })
    expect(firstAcknowledged.status).toBe(200)

    const second = await request(`/v1/gateways/gateway-session/commands?cursor=${encodeURIComponent(firstPage.cursor)}&wait_ms=0&limit=1`, {
      headers: { 'x-meshsetu-gateway-key': 'meshsetu-test-gateway' },
    })
    const secondPage = await second.json() as { cursor: string; commands: Array<{ response_id: string }> }
    expect(secondPage.commands.map(command => command.response_id)).toEqual(['same-ms-b'])
    expect(secondPage.cursor).toBe(`${createdAtMs}:same-ms-b`)
  })
})
