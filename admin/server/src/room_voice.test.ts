import { afterAll, beforeAll, expect, test } from 'vitest'
import WebSocket from 'ws'

process.env.NODE_ENV = 'test'
process.env.DATABASE_URL = ''
process.env.MESHSETU_GATEWAY_SECRET = 'voice-test-key'
const { server } = await import('./server.js')

let base = ''
const sockets: WebSocket[] = []

// 1.2 KB of pseudo-audio, comparable to a one-second 12 kbps Opus clip.
const audio = Buffer.from(Array.from({ length: 1200 }, (_, i) => (i * 7 + 3) % 256)).toString('base64')

beforeAll(async () => {
  await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve))
  const address = server.address() as { port: number }
  base = `ws://127.0.0.1:${address.port}/v1/rooms/stream`
})

afterAll(async () => {
  for (const socket of sockets) socket.close()
  await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()))
})

function connect() {
  return new Promise<WebSocket>((resolve, reject) => {
    const socket = new WebSocket(base)
    sockets.push(socket)
    socket.once('open', () => resolve(socket))
    socket.once('error', reject)
  })
}

function nextMessage(socket: WebSocket, type: string) {
  return new Promise<any>((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off('message', onMessage)
      reject(new Error(`timed out waiting for ${type}`))
    }, 2000)
    const onMessage = (raw: WebSocket.RawData) => {
      const message = JSON.parse(raw.toString())
      if (message.type !== type) return
      clearTimeout(timer)
      socket.off('message', onMessage)
      resolve(message)
    }
    socket.on('message', onMessage)
  })
}

function noMessage(socket: WebSocket, type: string, ms = 300) {
  return new Promise<boolean>(resolve => {
    const onMessage = (raw: WebSocket.RawData) => {
      if (JSON.parse(raw.toString()).type !== type) return
      socket.off('message', onMessage)
      resolve(false)
    }
    socket.on('message', onMessage)
    setTimeout(() => { socket.off('message', onMessage); resolve(true) }, ms)
  })
}

async function join(socket: WebSocket, memberId: string, roomId = 'room') {
  const joined = nextMessage(socket, 'room-joined')
  socket.send(JSON.stringify({
    type: 'join-room',
    siteId: 'site',
    roomId,
    memberId,
    displayName: memberId,
    gatewayKey: 'voice-test-key',
  }))
  await joined
}

test('relays a voice note to other members and acknowledges the recipient count', async () => {
  const sender = await connect()
  await join(sender, 'voice-sender')

  const soloAck = nextMessage(sender, 'room-voice-accepted')
  sender.send(JSON.stringify({ type: 'room-voice', messageId: 'solo-clip', audio, durationMs: 1000, sentAtMs: Date.now() }))
  expect((await soloAck).data).toMatchObject({ messageId: 'solo-clip', recipientCount: 0 })

  const receiver = await connect()
  await join(receiver, 'voice-receiver')
  const accepted = nextMessage(sender, 'room-voice-accepted')
  const received = nextMessage(receiver, 'room-voice')
  sender.send(JSON.stringify({ type: 'room-voice', messageId: 'shared-clip', audio, durationMs: 2500, sentAtMs: 4242 }))

  expect((await accepted).data).toMatchObject({ messageId: 'shared-clip', recipientCount: 1 })
  expect((await received).data).toMatchObject({
    messageId: 'shared-clip',
    audio,
    durationMs: 2500,
    memberId: 'voice-sender',
    displayName: 'voice-sender',
    sentAtMs: 4242,
  })
})

test('a voice note never leaks into another room', async () => {
  const sender = await connect()
  await join(sender, 'room-a-sender', 'room-a')
  const outsider = await connect()
  await join(outsider, 'room-b-member', 'room-b')

  const silence = noMessage(outsider, 'room-voice')
  const accepted = nextMessage(sender, 'room-voice-accepted')
  sender.send(JSON.stringify({ type: 'room-voice', messageId: 'scoped', audio, durationMs: 900, sentAtMs: Date.now() }))

  expect((await accepted).data.recipientCount).toBe(0)
  expect(await silence).toBe(true)
})

test('rejects malformed voice frames without disturbing the text path', async () => {
  const sender = await connect()
  await join(sender, 'malformed-sender')
  const receiver = await connect()
  await join(receiver, 'malformed-receiver')

  // Not base64, over the duration cap, and missing audio: all must be dropped.
  const silence = noMessage(receiver, 'room-voice')
  sender.send(JSON.stringify({ type: 'room-voice', messageId: 'bad-b64', audio: 'not base64!!', durationMs: 500, sentAtMs: Date.now() }))
  sender.send(JSON.stringify({ type: 'room-voice', messageId: 'too-long', audio, durationMs: 9000, sentAtMs: Date.now() }))
  sender.send(JSON.stringify({ type: 'room-voice', messageId: 'no-audio', durationMs: 500, sentAtMs: Date.now() }))
  expect(await silence).toBe(true)

  // The shared handler must still serve text after those rejections.
  const text = nextMessage(receiver, 'room-message')
  sender.send(JSON.stringify({ type: 'room-message', messageId: 'still-works', text: 'text after voice', sentAtMs: Date.now() }))
  expect((await text).data).toMatchObject({ messageId: 'still-works', text: 'text after voice' })
})

test('a voice frame before joining is refused', async () => {
  const socket = await connect()
  const closed = new Promise<number>(resolve => socket.once('close', code => resolve(code)))
  socket.send(JSON.stringify({ type: 'room-voice', messageId: 'unjoined', audio, durationMs: 500, sentAtMs: Date.now() }))

  expect(await closed).toBe(1008)
})
