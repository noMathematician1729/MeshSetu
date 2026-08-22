import { fast2SmsConfigured, indianSubscriberNumber, sendFast2Sms } from './fast2sms.js'
import { sendEmergencySms, twilioSmsConfigured } from './twilio_sms.js'

export type SmsDispatchResult =
  | { state: 'sent'; provider: string; providerMessageSid: string; attemptFailures: string[] }
  | { state: 'failed'; reason: string }
  | { state: 'no-provider'; reason: string }

/**
 * Provider preference for one destination, used when `SMS_PROVIDER_ORDER` is
 * not explicitly configured.
 *
 * Indian numbers are attempted on Fast2SMS first. A US Twilio long code cannot
 * deliver SMS to India — the number is restricted to domestic destinations and
 * Twilio rejects the send outright (error 21659/21608) — so trying Twilio first
 * for a +91 contact only adds latency and buries the real Fast2SMS outcome
 * behind a guaranteed failure. Every other destination keeps Twilio first,
 * since Fast2SMS only serves +91 numbers.
 *
 * The non-preferred provider always remains as a fallback, so no destination
 * loses coverage when the preferred one is unconfigured or rejects the message.
 */
export function providerOrderFor(
  to: string,
  env: NodeJS.ProcessEnv = process.env,
): string[] {
  const configured = env.SMS_PROVIDER_ORDER?.trim()
  if (configured) {
    // An explicit operator override wins over destination-based defaults.
    return configured
      .split(',')
      .map((name) => name.trim().toLowerCase())
      .filter(Boolean)
  }
  return indianSubscriberNumber(to) ? ['fast2sms', 'twilio'] : ['twilio', 'fast2sms']
}

/**
 * Tries each configured transport in order until one accepts the message.
 * Emergency delivery must not depend on a single provider: Twilio trial
 * accounts cannot reach unverified Indian numbers, while Fast2SMS covers
 * India but no other country.
 *
 * A success carries `attemptFailures` describing any provider that was tried
 * and rejected first. Callers must log these: without them, a permanently
 * broken primary provider (an unfunded Fast2SMS wallet, an expired key) fails
 * invisibly on every send for as long as the fallback keeps working.
 */
export async function dispatchSms(
  to: string,
  body: string,
  options: { env?: NodeJS.ProcessEnv } = {},
): Promise<SmsDispatchResult> {
  const env = options.env ?? process.env
  const order = providerOrderFor(to, env)

  const failures: string[] = []
  let attempted = false
  for (const provider of order) {
    if (provider === 'twilio') {
      if (!twilioSmsConfigured(env)) continue
      attempted = true
      const result = await sendEmergencySms(to, body, { env })
      if (result.state === 'sent') {
        return { state: 'sent', provider, providerMessageSid: result.providerMessageSid, attemptFailures: failures }
      }
      failures.push(`twilio: ${result.reason}`)
    } else if (provider === 'fast2sms') {
      if (!fast2SmsConfigured(env)) continue
      attempted = true
      const result = await sendFast2Sms(to, body, { env })
      if (result.state === 'sent') {
        return { state: 'sent', provider, providerMessageSid: result.providerMessageSid, attemptFailures: failures }
      }
      failures.push(`fast2sms: ${result.reason}`)
    }
  }
  if (!attempted) {
    return { state: 'no-provider', reason: 'no SMS provider is enabled or configured' }
  }
  return { state: 'failed', reason: failures.join(' | ').slice(0, 400) }
}

export function anySmsProviderConfigured(env: NodeJS.ProcessEnv = process.env): boolean {
  return twilioSmsConfigured(env) || fast2SmsConfigured(env)
}
