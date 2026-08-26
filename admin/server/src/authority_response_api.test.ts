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
