import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'
import protobuf from 'protobufjs'

export const AUTHORITY_ALGORITHM = 'ECDSA_P256_SHA256' as const
export const P1363_SIGNATURE_BYTES = 64
const MAX_MESSAGE_UTF8_BYTES = 256

let rootPromise: Promise<protobuf.Root> | undefined
let material: { privateKey: crypto.KeyObject; publicJwk: AuthorityPublicJwk } | undefined

// Explicitly non-production bootstrap key. Its public half is pinned in
// development EventManifests so local server restarts cannot invalidate a
// sender's responder-update verification key. Never use this key in a real
// deployment; production below requires a deployment secret instead.
const developmentPrivateKeyPem = `-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgyuaCpkXAv5TjaIvZ
BQwC5rc/wh0JL9SUYzmK2iaRPCOhRANCAASw8V053zj5ADOfTzii76zvHIoq9ijr
8rrA46NyMts9HDOknPB/6AJ3qAQwHWGVFPwrXGjAf8976Lq5LJSEPQw5
-----END PRIVATE KEY-----
`

export type AuthorityPublicJwk = {
  kty: 'EC'
  crv: 'P-256'
  x: string
  y: string
}

function protocolRoot() {
  const candidates = [
    path.join(import.meta.dirname, 'protocol', 'meshsetu.proto'),
    path.join(import.meta.dirname, '../src/protocol/meshsetu.proto'),
    path.join(import.meta.dirname, '../../src/protocol/meshsetu.proto'),
  ]
  const proto = candidates.find(candidate => fs.existsSync(candidate))
  if (!proto) throw new Error('meshsetu.proto not found')
  rootPromise ??= protobuf.load(proto)
  return rootPromise
}

function privateKeyPem() {
  const encoded = process.env.MESHSETU_AUTHORITY_PRIVATE_KEY_PEM_B64
  if (encoded) return Buffer.from(encoded, 'base64').toString('utf8')
  if (process.env.MESHSETU_AUTHORITY_PRIVATE_KEY_PEM) return process.env.MESHSETU_AUTHORITY_PRIVATE_KEY_PEM
  if (process.env.NODE_ENV === 'production') {
    throw new Error('MESHSETU_AUTHORITY_PRIVATE_KEY_PEM_B64 is required in production')
  }
  return developmentPrivateKeyPem
}

function authorityMaterial() {
  if (material) return material
  const privateKey = crypto.createPrivateKey(privateKeyPem())
  const jwk = privateKey.export({ format: 'jwk' }) as Partial<AuthorityPublicJwk>
  if (jwk.kty !== 'EC' || jwk.crv !== 'P-256' || typeof jwk.x !== 'string' || typeof jwk.y !== 'string') {
    throw new Error('authority key is not P-256 JWK-compatible')
  }
  material = { privateKey, publicJwk: { kty: 'EC', crv: 'P-256', x: jwk.x, y: jwk.y } }
  return material
}

export function authorityKeyId() {
  return process.env.MESHSETU_AUTHORITY_KEY_ID || 'meshsetu-authority-dev-v1'
}

export function authorityPublicKeyJwk(): AuthorityPublicJwk {
  return { ...authorityMaterial().publicJwk }
}

export function signBody(bodyBytes: Uint8Array): Buffer {
  const signature = crypto.createSign('SHA256').update(bodyBytes).end().sign({
    key: authorityMaterial().privateKey,
    dsaEncoding: 'ieee-p1363',
  })
  if (signature.length !== P1363_SIGNATURE_BYTES) {
    throw new Error(`expected 64-byte P1363 signature, got ${signature.length}`)
  }
  return signature
}

export type ResponderBodyInput = {
  responseId: string
  replyToEventId: string
  destinationEphemeralId: string
  type: 'SOS_RECEIVED' | 'HELP_DISPATCHED' | 'SAFETY_GUIDANCE' | 'INCIDENT_CLOSED'
  messageText: string
  createdAtMs: number
  expiresAtMs: number
  siteId: string
  originalTraceId?: Uint8Array
}

function parseSignedInt64(value: string) {
  if (!/^(0|[1-9][0-9]*)$/.test(value)) throw new Error('ephemeral ID must be a decimal integer')
  const parsed = BigInt(value)
  if (parsed < 0n || parsed > 0x7fffffffffffffffn) throw new Error('ephemeral ID is outside the mobile int64 range')
  return parsed.toString()
}

export async function encodeAndSignResponderUpdate(input: ResponderBodyInput) {
  if (Buffer.byteLength(input.messageText, 'utf8') > MAX_MESSAGE_UTF8_BYTES) {
    throw new Error('message_text exceeds 256 UTF-8 bytes')
  }
  if (!input.responseId || !input.replyToEventId || !input.siteId) throw new Error('response/event/site IDs are required')
  if (!Number.isSafeInteger(input.createdAtMs) || !Number.isSafeInteger(input.expiresAtMs) || input.expiresAtMs <= input.createdAtMs) {
    throw new Error('invalid response timestamps')
  }
  const root = await protocolRoot()
  const bodyType = root.lookupType('meshsetu.v1.ResponderUpdateBody')
  const signedType = root.lookupType('meshsetu.v1.SignedResponderUpdate')
  const body = bodyType.fromObject({
    responseId: input.responseId,
    replyToEventId: input.replyToEventId,
    destinationEphemeralId: parseSignedInt64(input.destinationEphemeralId),
    type: input.type,
    messageText: input.messageText,
    createdAtMs: input.createdAtMs,
    expiresAtMs: input.expiresAtMs,
    siteId: input.siteId,
    originalTraceId: Buffer.from(input.originalTraceId ?? []),
  })
  const bodyBytes = Buffer.from(bodyType.encode(body).finish())
  const signature = signBody(bodyBytes)
  const signed = signedType.fromObject({
    body: bodyBytes,
    authoritySignature: signature,
    authorityKeyId: authorityKeyId(),
    algorithm: 'ECDSA_P256_SHA256',
  })
  return {
    bodyBytes,
    signedBytes: Buffer.from(signedType.encode(signed).finish()),
    signature,
    keyId: authorityKeyId(),
    publicJwk: authorityPublicKeyJwk(),
  }
}

export async function verifyBodySignature(bodyBytes: Uint8Array, signature: Uint8Array) {
  if (signature.length !== P1363_SIGNATURE_BYTES) return false
  return crypto.verify('sha256', bodyBytes, {
    key: authorityMaterial().privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
    dsaEncoding: 'ieee-p1363',
  }, signature)
}
