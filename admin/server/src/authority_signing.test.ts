import { afterEach, describe, expect, it } from 'vitest'
import protobuf from 'protobufjs'
import path from 'node:path'

process.env.NODE_ENV = 'test'
process.env.DATABASE_URL = ''

const { encodeAndSignResponderUpdate, verifyBodySignature } = await import('./authority_signing.js')

describe('authority response signing', () => {
  afterEach(() => {
    delete process.env.MESHSETU_AUTHORITY_PRIVATE_KEY_PEM_B64
  })

  it('signs and verifies exact body bytes with 64-byte IEEE P1363', async () => {
    const result = await encodeAndSignResponderUpdate({
      responseId: 'response-test',
      replyToEventId: 'event-test',
      destinationEphemeralId: '9223372036854770000',
      type: 'SOS_RECEIVED',
      messageText: 'Your SOS reached the control room.',
      createdAtMs: 1700000000000,
      expiresAtMs: 1700000300000,
      siteId: 'site-test',
    })
    expect(result.signature).toHaveLength(64)
    expect(await verifyBodySignature(result.bodyBytes, result.signature)).toBe(true)
    const changed = Buffer.from(result.bodyBytes)
    changed[changed.length - 1] ^= 1
    expect(await verifyBodySignature(changed, result.signature)).toBe(false)
  })

  it('serializes destination ephemeral ID as fixed64 and rejects oversized UTF-8', async () => {
    const result = await encodeAndSignResponderUpdate({
      responseId: 'response-fixed64', replyToEventId: 'event-fixed64', destinationEphemeralId: '123456789',
      type: 'SAFETY_GUIDANCE', messageText: 'é'.repeat(128), createdAtMs: 1, expiresAtMs: 2, siteId: 'site',
    })
    const root = await protobuf.load(path.join(import.meta.dirname, 'protocol', 'meshsetu.proto'))
    const type = root.lookupType('meshsetu.v1.ResponderUpdateBody')
    const decoded: any = type.toObject(type.decode(result.bodyBytes), { longs: String, enums: String, bytes: Buffer })
    expect(decoded.destinationEphemeralId).toBe('123456789')
    await expect(encodeAndSignResponderUpdate({
      responseId: 'too-long', replyToEventId: 'event', destinationEphemeralId: '1', type: 'SAFETY_GUIDANCE',
      messageText: '🚨'.repeat(65), createdAtMs: 1, expiresAtMs: 2, siteId: 'site',
    })).rejects.toThrow('256 UTF-8 bytes')
  })
})
