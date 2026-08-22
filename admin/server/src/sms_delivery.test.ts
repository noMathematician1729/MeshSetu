import { describe, expect, it } from 'vitest'
import { dispatchSms, providerOrderFor } from './sms_delivery.js'
import { indianSubscriberNumber } from './fast2sms.js'
import { buildCompactEmergencySms } from './twilio_sms.js'

const twilioEnv = {
  TWILIO_SMS_ENABLED: 'true',
  TWILIO_ACCOUNT_SID: 'AC-test',
  TWILIO_AUTH_TOKEN: 'token',
  TWILIO_FROM_NUMBER: '+15092849424',
} as NodeJS.ProcessEnv

const indianContact = '+919131744308'

describe('Fast2SMS recipient normalization', () => {
  it('accepts Indian numbers in E.164 or local form and rejects others', () => {
    expect(indianSubscriberNumber('+919573804520')).toBe('9573804520')
    expect(indianSubscriberNumber('9573804520')).toBe('9573804520')
    expect(indianSubscriberNumber('+15095551234')).toBeUndefined()
    expect(indianSubscriberNumber('123')).toBeUndefined()
  })
})

describe('destination-aware provider ordering', () => {
  it('prefers Fast2SMS for Indian destinations', () => {
    expect(providerOrderFor(indianContact, {} as NodeJS.ProcessEnv)).toEqual(['fast2sms', 'twilio'])
  })

  it('prefers Twilio for non-Indian destinations', () => {
    expect(providerOrderFor('+15095551234', {} as NodeJS.ProcessEnv)).toEqual(['twilio', 'fast2sms'])
  })

  it('lets an explicit SMS_PROVIDER_ORDER override the Indian default', () => {
    const env = { SMS_PROVIDER_ORDER: 'twilio,fast2sms' } as NodeJS.ProcessEnv
    expect(providerOrderFor(indianContact, env)).toEqual(['twilio', 'fast2sms'])
  })
})

describe('compact emergency SMS body', () => {
  const record = {
    reporter_name: 'shaurya',
    reporter_uid: '43b85d6413af',
    incident_type: 'general',
    latitude: 17.385,
    longitude: 78.4867,
    status: 'new',
    priority: 'p0Critical',
  }

  it('fits one GSM-7 segment and keeps the actionable details', () => {
    const body = buildCompactEmergencySms(record, 'dhanya', 'https://example.com/sos/ceal-43b85d6413af-1787390107855')
    expect(body.length).toBeLessThanOrEqual(160)
    expect(body).toContain('shaurya')
    expect(body).toContain('https://maps.google.com/?q=')
    expect(body).toContain('Call 112.')
    expect(body).not.toContain('null')
    expect(body).not.toContain('undefined')
  })

  it('omits location instead of printing null when coordinates are missing', () => {
    const body = buildCompactEmergencySms({ reporter_name: 'shaurya', incident_type: 'medical' })
    expect(body).not.toContain('null')
    expect(body).not.toContain('maps.google.com')
    expect(body).toContain('Call 112.')
  })

  it('falls back to the reporter UID when no name resolved', () => {
    const body = buildCompactEmergencySms({ reporter_uid: '43b85d6413af' })
    expect(body).toContain('43b85d6413af')
  })
})

describe('multi-provider SMS delivery', () => {
  it('sends an Indian number through Fast2SMS first, without calling Twilio', async () => {
    const calls: string[] = []
    const originalFetch = globalThis.fetch
    globalThis.fetch = (async (input: RequestInfo | URL) => {
      const url = String(input)
      calls.push(url)
      return new Response(JSON.stringify({ return: true, request_id: 'f2s-primary' }), { status: 200, headers: { 'content-type': 'application/json' } })
    }) as typeof fetch

    try {
      const result = await dispatchSms(indianContact, 'emergency', {
        env: { ...twilioEnv, FAST2SMS_API_KEY: 'f2s-key' } as NodeJS.ProcessEnv,
      })
      expect(result).toMatchObject({ state: 'sent', provider: 'fast2sms', providerMessageSid: 'f2s-primary' })
      expect(calls).toHaveLength(1)
      expect(calls[0]).toContain('fast2sms.com')
    } finally {
      globalThis.fetch = originalFetch
    }
  })

  it('falls back to Twilio when Fast2SMS rejects an Indian number', async () => {
    const calls: string[] = []
    const originalFetch = globalThis.fetch
    globalThis.fetch = (async (input: RequestInfo | URL) => {
      const url = String(input)
      calls.push(url)
      if (url.startsWith('https://www.fast2sms.com/')) {
        return new Response(JSON.stringify({ return: false, message: ['Invalid Authentication'] }), { status: 401, headers: { 'content-type': 'application/json' } })
      }
      return new Response(JSON.stringify({ sid: 'SM-fallback' }), { status: 201, headers: { 'content-type': 'application/json' } })
    }) as typeof fetch

    try {
      const result = await dispatchSms(indianContact, 'emergency', {
        env: { ...twilioEnv, FAST2SMS_API_KEY: 'f2s-key' } as NodeJS.ProcessEnv,
      })
      expect(result).toMatchObject({ state: 'sent', provider: 'twilio', providerMessageSid: 'SM-fallback' })
      expect(calls[0]).toContain('fast2sms.com')
      expect(calls[1]).toContain('api.twilio.com')
      // The masked primary-provider rejection must still be reported.
      expect(result.state === 'sent' && result.attemptFailures).toHaveLength(1)
      expect(result.state === 'sent' && result.attemptFailures[0]).toContain('fast2sms')
    } finally {
      globalThis.fetch = originalFetch
    }
  })

  it('reports no attempt failures when the preferred provider succeeds', async () => {
    const originalFetch = globalThis.fetch
    globalThis.fetch = (async () =>
      new Response(JSON.stringify({ return: true, request_id: 'f2s-clean' }), { status: 200, headers: { 'content-type': 'application/json' } })) as typeof fetch
    try {
      const result = await dispatchSms(indianContact, 'emergency', {
        env: { ...twilioEnv, FAST2SMS_API_KEY: 'f2s-key' } as NodeJS.ProcessEnv,
      })
      expect(result.state === 'sent' && result.attemptFailures).toEqual([])
    } finally {
      globalThis.fetch = originalFetch
    }
  })

  it('falls back to Fast2SMS when Twilio rejects an unverified Indian number', async () => {
    const calls: string[] = []
    const originalFetch = globalThis.fetch
    globalThis.fetch = (async (input: RequestInfo | URL) => {
      const url = String(input)
      calls.push(url)
      if (url.startsWith('https://api.twilio.com/')) {
        // Real trial-account behaviour observed against Twilio: error 21608.
        return new Response(JSON.stringify({ code: 21608, message: 'unverified number' }), { status: 400, headers: { 'content-type': 'application/json' } })
      }
      return new Response(JSON.stringify({ return: true, request_id: 'f2s-1' }), { status: 200, headers: { 'content-type': 'application/json' } })
    }) as typeof fetch

    try {
      // Explicit order forces the historical Twilio-first behaviour.
      const result = await dispatchSms('+919573804520', 'emergency', {
        env: { ...twilioEnv, FAST2SMS_API_KEY: 'f2s-key', SMS_PROVIDER_ORDER: 'twilio,fast2sms' } as NodeJS.ProcessEnv,
      })
      expect(result).toMatchObject({ state: 'sent', provider: 'fast2sms', providerMessageSid: 'f2s-1' })
      expect(calls[0]).toContain('api.twilio.com')
      expect(calls[1]).toContain('fast2sms.com')
    } finally {
      globalThis.fetch = originalFetch
    }
  })

  it('reports every provider failure when none accepts the message', async () => {
    const originalFetch = globalThis.fetch
    globalThis.fetch = (async () =>
      new Response(JSON.stringify({ code: 21608, message: 'unverified number' }), { status: 400, headers: { 'content-type': 'application/json' } })) as typeof fetch
    try {
      const result = await dispatchSms('+919573804520', 'emergency', { env: twilioEnv })
      expect(result.state).toBe('failed')
      expect(result.state === 'failed' && result.reason).toContain('twilio')
    } finally {
      globalThis.fetch = originalFetch
    }
  })

  it('reports no-provider when nothing is configured', async () => {
    const result = await dispatchSms('+919573804520', 'emergency', { env: {} as NodeJS.ProcessEnv })
    expect(result.state).toBe('no-provider')
  })
})
