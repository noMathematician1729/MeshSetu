import { Pool } from 'pg'
import type { TriageResult } from './triage.js'

export type EventRecord = Record<string, any>
export type ProfileRecord = { reporter_uid: string; name: string; phone: string; language: string; blood_group: string; allergies: string; conditions: string; primary_contact_name: string; primary_contact_phone: string; emergency_contacts: any[]; registered_at_ms: number; updated_at?: string }
export type NotificationRecord = { notification_id: string; event_id: string; recipient_type: 'admin' | 'emergency_contact' | 'relay'; recipient_key: string; update_type: string; title: string; body: string; public_url: string; created_at_ms: number }
export type SmsDeliveryRecord = { sms_delivery_id: string; event_id: string; recipient_phone: string; recipient_name: string | null; state: 'reserved' | 'sent' | 'failed'; provider_message_sid: string | null; failure_reason: string | null; created_at_ms: number; completed_at_ms: number | null }
export type AuthorityResponseState = 'SIGNED' | 'GATEWAY_RECEIVED' | 'MESH_QUEUED' | 'FORWARDING' | 'SENDER_DELIVERED' | 'RECEIPT_AT_DASHBOARD' | 'EXPIRED' | 'FAILED'
export type AuthorityResponseRecord = {
  response_id: string; event_id: string; reply_to_event_id?: string | null; site_id: string; response_type: string;
  message_text: string; destination_ephemeral_id: string; signed_payload: Buffer;
  key_id: string; state: AuthorityResponseState;
  route_mode: string | null; return_hops: number; retry_count: number; created_at_ms: number; expires_at_ms: number;
  gateway_session_id: string | null; trace_id: Buffer | null; original_trace_id: Buffer | null;
  mesh_object_id?: number | null; last_error?: string | null;
}

export const authorityResponseStateRank: Record<AuthorityResponseState, number> = {
  SIGNED: 0,
  GATEWAY_RECEIVED: 1,
  MESH_QUEUED: 2,
  FORWARDING: 3,
  SENDER_DELIVERED: 4,
  RECEIPT_AT_DASHBOARD: 5,
  EXPIRED: 6,
  FAILED: 6,
}

export const isAuthorityResponseTerminal = (state: AuthorityResponseState) =>
  state === 'RECEIPT_AT_DASHBOARD' || state === 'EXPIRED' || state === 'FAILED'
export type AuthorityReceiptRecord = { receipt_id: string; response_id: string; reply_to_event_id: string; sender_ephemeral_id: string; created_at_ms: number; received_at_ms: number }
export class EventStore {
  pool?: Pool
  memory = new Map<string, EventRecord>()
  profiles = new Map<string, ProfileRecord>()
  notifications = new Map<string, NotificationRecord>()
  smsDeliveries = new Map<string, SmsDeliveryRecord>()
  authorityResponses = new Map<string, AuthorityResponseRecord>()
  authorityReceipts = new Map<string, AuthorityReceiptRecord>()
  authorityIdempotency = new Map<string, { responseId: string; requestHash: string }>()
  constructor() { if (process.env.DATABASE_URL) this.pool = new Pool({ connectionString: process.env.DATABASE_URL }) }
  async init() {
    if (!this.pool) return
    await this.pool.query(`CREATE TABLE IF NOT EXISTS sos_incidents (event_id text PRIMARY KEY, object_id text UNIQUE NOT NULL, site_id text NOT NULL, room_id text, priority text NOT NULL, incident_type text NOT NULL, transcript text, stt_confidence real, triage_confidence real, hazards jsonb NOT NULL DEFAULT '[]', rationale jsonb NOT NULL DEFAULT '[]', triage jsonb NOT NULL DEFAULT '{}', input_mode text, zone text, latitude double precision, longitude double precision, accuracy_m real, location_captured_at_ms bigint, hops integer NOT NULL DEFAULT 0, relay_latency_ms integer, created_at_ms bigint, expires_at_ms bigint, received_at_ms bigint NOT NULL, packet_sha256 text NOT NULL, decrypt_status text NOT NULL, voice_clip_id text, audio_state text, status text NOT NULL DEFAULT 'new', audio_bytes bytea, audio_sha256 text, audio_content_type text, reporter_uid text, reporter_name text, reporter_phone text, reporter_language text, reporter_blood_group text, reporter_primary_contact text, updated_at timestamptz NOT NULL DEFAULT now())`)
    // Migration: add reporter columns to existing tables created before this schema version.
    await this.pool.query(`DO $$ BEGIN
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS reporter_uid text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS reporter_name text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS reporter_phone text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS reporter_language text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS reporter_blood_group text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS reporter_primary_contact text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS compact_sequence integer;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS triage jsonb NOT NULL DEFAULT '{}';
    END $$`)
    await this.pool.query(`CREATE TABLE IF NOT EXISTS user_profiles (reporter_uid text PRIMARY KEY, name text NOT NULL, phone text NOT NULL, language text NOT NULL DEFAULT 'English', blood_group text, allergies text, conditions text, primary_contact_name text, primary_contact_phone text, emergency_contacts jsonb NOT NULL DEFAULT '[]', registered_at_ms bigint NOT NULL, updated_at timestamptz NOT NULL DEFAULT now())`)
    await this.pool.query(`CREATE TABLE IF NOT EXISTS sos_notification_deliveries (notification_id text PRIMARY KEY, event_id text NOT NULL REFERENCES sos_incidents(event_id) ON DELETE CASCADE, recipient_type text NOT NULL, recipient_key text NOT NULL, update_type text NOT NULL, title text NOT NULL, body text NOT NULL, public_url text NOT NULL, created_at_ms bigint NOT NULL)`)
    await this.pool.query(`CREATE INDEX IF NOT EXISTS sos_notification_deliveries_recipient_idx ON sos_notification_deliveries (recipient_key, created_at_ms DESC)`)
    // The primary key is the idempotency boundary: duplicate BLE relays cannot
    // create a second carrier submission for one SOS and contact.
    await this.pool.query(`CREATE TABLE IF NOT EXISTS sos_sms_deliveries (sms_delivery_id text PRIMARY KEY, event_id text NOT NULL REFERENCES sos_incidents(event_id) ON DELETE CASCADE, recipient_phone text NOT NULL, recipient_name text, state text NOT NULL, provider_message_sid text, failure_reason text, created_at_ms bigint NOT NULL, completed_at_ms bigint)`)
    await this.pool.query(`CREATE INDEX IF NOT EXISTS sos_sms_deliveries_event_idx ON sos_sms_deliveries (event_id, created_at_ms DESC)`)
    await this.pool.query(`CREATE TABLE IF NOT EXISTS authority_responses (response_id text PRIMARY KEY, event_id text NOT NULL REFERENCES sos_incidents(event_id) ON DELETE CASCADE, reply_to_event_id text, site_id text NOT NULL, destination_ephemeral_id text NOT NULL, response_type text NOT NULL, message_text text NOT NULL, signed_payload bytea NOT NULL, key_id text NOT NULL, state text NOT NULL, route_mode text, return_hops integer NOT NULL DEFAULT 0, retry_count integer NOT NULL DEFAULT 0, last_error text, mesh_object_id bigint, created_at_ms bigint NOT NULL, expires_at_ms bigint NOT NULL, gateway_session_id text, trace_id bytea, original_trace_id bytea)`)
    await this.pool.query(`CREATE INDEX IF NOT EXISTS authority_responses_gateway_idx ON authority_responses (state, created_at_ms)`)
    await this.pool.query(`CREATE TABLE IF NOT EXISTS authority_response_idempotency (idempotency_key text PRIMARY KEY, response_id text NOT NULL REFERENCES authority_responses(response_id) ON DELETE CASCADE, request_hash text NOT NULL)`)
    await this.pool.query(`DO $$ BEGIN ALTER TABLE authority_responses ADD COLUMN IF NOT EXISTS last_error text; ALTER TABLE authority_responses ADD COLUMN IF NOT EXISTS mesh_object_id bigint; ALTER TABLE authority_responses ADD COLUMN IF NOT EXISTS reply_to_event_id text; END $$`)
    await this.pool.query(`CREATE TABLE IF NOT EXISTS authority_response_receipts (receipt_id text PRIMARY KEY, response_id text NOT NULL REFERENCES authority_responses(response_id) ON DELETE CASCADE, reply_to_event_id text NOT NULL, sender_ephemeral_id text NOT NULL, created_at_ms bigint NOT NULL, received_at_ms bigint NOT NULL)`)
    await this.pool.query(`DO $$ BEGIN
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS origin_ephemeral_id text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS ingress_gateway_session_id text;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS trace_id bytea;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS forward_hop_count integer NOT NULL DEFAULT 0;
      ALTER TABLE sos_incidents ADD COLUMN IF NOT EXISTS return_event_id text;
    END $$`)
  }
  async upsert(record: EventRecord) {
    const existing = this.memory.get(record.event_id)
    const merged = { ...existing, ...record, updated_at: new Date().toISOString() }
    this.memory.set(record.event_id, merged)
    if (this.pool) await this.pool.query(`INSERT INTO sos_incidents (event_id, object_id, site_id, room_id, priority, incident_type, transcript, stt_confidence, triage_confidence, hazards, rationale, input_mode, zone, latitude, longitude, accuracy_m, location_captured_at_ms, hops, relay_latency_ms, created_at_ms, expires_at_ms, received_at_ms, packet_sha256, decrypt_status, voice_clip_id, audio_state, status, audio_bytes, audio_sha256, audio_content_type, reporter_uid, reporter_name, reporter_phone, reporter_language, reporter_blood_group, reporter_primary_contact, compact_sequence) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37) ON CONFLICT (event_id) DO UPDATE SET object_id=COALESCE(EXCLUDED.object_id,sos_incidents.object_id), priority=COALESCE(EXCLUDED.priority,sos_incidents.priority), incident_type=COALESCE(EXCLUDED.incident_type,sos_incidents.incident_type), transcript=COALESCE(EXCLUDED.transcript,sos_incidents.transcript), hazards=CASE WHEN jsonb_array_length(EXCLUDED.hazards) > 0 THEN EXCLUDED.hazards ELSE sos_incidents.hazards END, zone=COALESCE(EXCLUDED.zone,sos_incidents.zone), latitude=COALESCE(EXCLUDED.latitude,sos_incidents.latitude), longitude=COALESCE(EXCLUDED.longitude,sos_incidents.longitude), hops=GREATEST(sos_incidents.hops,EXCLUDED.hops), relay_latency_ms=COALESCE(EXCLUDED.relay_latency_ms,sos_incidents.relay_latency_ms), voice_clip_id=COALESCE(EXCLUDED.voice_clip_id,sos_incidents.voice_clip_id), audio_state=COALESCE(EXCLUDED.audio_state,sos_incidents.audio_state), status=sos_incidents.status, audio_bytes=COALESCE(EXCLUDED.audio_bytes,sos_incidents.audio_bytes), audio_sha256=COALESCE(EXCLUDED.audio_sha256,sos_incidents.audio_sha256), reporter_uid=COALESCE(EXCLUDED.reporter_uid,sos_incidents.reporter_uid), reporter_name=COALESCE(EXCLUDED.reporter_name,sos_incidents.reporter_name), reporter_phone=COALESCE(EXCLUDED.reporter_phone,sos_incidents.reporter_phone), reporter_language=COALESCE(EXCLUDED.reporter_language,sos_incidents.reporter_language), reporter_blood_group=COALESCE(EXCLUDED.reporter_blood_group,sos_incidents.reporter_blood_group), reporter_primary_contact=COALESCE(EXCLUDED.reporter_primary_contact,sos_incidents.reporter_primary_contact), compact_sequence=COALESCE(EXCLUDED.compact_sequence,sos_incidents.compact_sequence), updated_at=now()`, [record.event_id, record.object_id, record.site_id, record.room_id, record.priority, record.incident_type, record.transcript, record.stt_confidence, record.triage_confidence, JSON.stringify(record.hazards ?? []), JSON.stringify(record.rationale ?? []), record.input_mode, record.zone, record.latitude, record.longitude, record.accuracy_m, record.location_captured_at_ms, record.hops ?? 0, record.relay_latency_ms, record.created_at_ms, record.expires_at_ms, record.received_at_ms ?? Date.now(), record.packet_sha256, record.decrypt_status ?? 'verified', record.voice_clip_id, record.audio_state, record.status ?? 'new', record.audio_bytes ?? null, record.audio_sha256 ?? null, record.audio_content_type ?? null, record.reporter_uid ?? null, record.reporter_name ?? null, record.reporter_phone ?? null, record.reporter_language ?? null, record.reporter_blood_group ?? null, record.reporter_primary_contact ?? null, record.compact_sequence ?? null])
    if (this.pool && (record.origin_ephemeral_id != null || record.ingress_gateway_session_id != null || record.trace_id != null || record.forward_hop_count != null || record.return_event_id != null)) {
      await this.pool.query('UPDATE sos_incidents SET origin_ephemeral_id=COALESCE($2,origin_ephemeral_id), ingress_gateway_session_id=COALESCE($3,ingress_gateway_session_id), trace_id=COALESCE($4,trace_id), forward_hop_count=COALESCE($5,forward_hop_count), return_event_id=COALESCE($6,return_event_id) WHERE event_id=$1', [record.event_id, record.origin_ephemeral_id?.toString?.() ?? null, record.ingress_gateway_session_id ?? null, record.trace_id ? Buffer.from(record.trace_id) : null, record.forward_hop_count ?? null, record.return_event_id ?? null])
    }
    return merged
  }
  async all() {
    const compare = (a: EventRecord, b: EventRecord) => (['p0Critical', 'p1High', 'p2Normal'].indexOf(a.priority) - ['p0Critical', 'p1High', 'p2Normal'].indexOf(b.priority))
      || (Number(b.triage?.score ?? 0) - Number(a.triage?.score ?? 0))
      || (Number(b.received_at_ms ?? 0) - Number(a.received_at_ms ?? 0))
    if (!this.pool) return [...this.memory.values()].sort(compare)
    const result = await this.pool.query("SELECT * FROM sos_incidents ORDER BY CASE priority WHEN 'p0Critical' THEN 0 WHEN 'p1High' THEN 1 WHEN 'p2Normal' THEN 2 ELSE 3 END, COALESCE((triage->>'score')::integer, 0) DESC, received_at_ms DESC")
    return result.rows
  }
  async get(id: string) { if (!this.pool) return this.memory.get(id); const result = await this.pool.query('SELECT * FROM sos_incidents WHERE event_id=$1', [id]); return result.rows[0] }
  async status(id: string, value: string) { const current = await this.get(id); if (!current) return undefined; const next = { ...current, status: value }; return this.upsert(next) }
  async recentForTriage(event: EventRecord, sinceMs: number): Promise<EventRecord[]> {
    const matches = (row: EventRecord) => row.event_id !== event.event_id
      && row.priority === 'p0Critical'
      && row.site_id === event.site_id
      && Number(row.received_at_ms ?? 0) >= sinceMs
    if (!this.pool) return [...this.memory.values()].filter(matches)
    const result = await this.pool.query('SELECT * FROM sos_incidents WHERE event_id <> $1 AND priority=$2 AND site_id=$3 AND received_at_ms >= $4 ORDER BY received_at_ms DESC', [event.event_id, 'p0Critical', event.site_id, sinceMs])
    return result.rows
  }
  async applyTriage(id: string, triage: TriageResult) {
    const current = await this.get(id)
    if (!current) return undefined
    const next = { ...current, triage, triage_confidence: triage.confidence, updated_at: new Date().toISOString() }
    this.memory.set(id, next)
    if (this.pool) {
      const result = await this.pool.query('UPDATE sos_incidents SET triage=$2, triage_confidence=$3, updated_at=now() WHERE event_id=$1 RETURNING *', [id, JSON.stringify(triage), triage.confidence])
      return result.rows[0]
    }
    return next
  }
  /// Multiple relays forward the same compact alert. Reusing the recent
  /// incident keeps one dashboard entry and one contact notification.
  async findRecentCompactEvent(reporterUid: string, sequence: number | null | undefined, sinceMs: number, siteId?: string): Promise<EventRecord | undefined> {
    if (sequence == null) return undefined
    const matches = (row: EventRecord) => {
      const sameReporter = row.reporter_uid === reporterUid
        || String(row.reporter_uid ?? '').startsWith(reporterUid)
        || reporterUid.startsWith(String(row.reporter_uid ?? ''))
      return sameReporter
        && row.compact_sequence === sequence
        && (!siteId || row.site_id === siteId)
        && Number(row.received_at_ms ?? 0) >= sinceMs
    }
    if (!this.pool) return [...this.memory.values()].filter(matches).sort((a, b) => Number(b.received_at_ms ?? 0) - Number(a.received_at_ms ?? 0))[0]
    const siteClause = siteId ? ' AND site_id=$4' : ''
    const params: Array<string | number> = [reporterUid, sequence, sinceMs]
    if (siteId) params.push(siteId)
    const result = await this.pool.query(`SELECT * FROM sos_incidents WHERE (reporter_uid=$1 OR reporter_uid LIKE $1 || '%' OR $1 LIKE reporter_uid || '%') AND compact_sequence=$2 AND received_at_ms >= $3${siteClause} ORDER BY received_at_ms DESC LIMIT 1`, params)
    return result.rows[0]
  }
  async upsertProfile(profile: ProfileRecord) {
    const merged = { ...profile, updated_at: new Date().toISOString() }
    this.profiles.set(profile.reporter_uid, merged)
    if (this.pool) await this.pool.query(`INSERT INTO user_profiles (reporter_uid, name, phone, language, blood_group, allergies, conditions, primary_contact_name, primary_contact_phone, emergency_contacts, registered_at_ms) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) ON CONFLICT (reporter_uid) DO UPDATE SET name=EXCLUDED.name, phone=EXCLUDED.phone, language=EXCLUDED.language, blood_group=EXCLUDED.blood_group, allergies=EXCLUDED.allergies, conditions=EXCLUDED.conditions, primary_contact_name=EXCLUDED.primary_contact_name, primary_contact_phone=EXCLUDED.primary_contact_phone, emergency_contacts=EXCLUDED.emergency_contacts, updated_at=now()`, [profile.reporter_uid, profile.name, profile.phone, profile.language, profile.blood_group ?? '', profile.allergies ?? '', profile.conditions ?? '', profile.primary_contact_name ?? '', profile.primary_contact_phone ?? '', JSON.stringify(profile.emergency_contacts ?? []), profile.registered_at_ms])
    return merged
  }
  async getProfile(uid: string): Promise<ProfileRecord | undefined> {
    if (!this.pool) return this.profiles.get(uid)
    const result = await this.pool.query('SELECT * FROM user_profiles WHERE reporter_uid=$1', [uid])
    return result.rows[0]
  }
  async getProfileByPrefix(uidPrefix: string): Promise<ProfileRecord | undefined> {
    if (uidPrefix.length < 6) return undefined
    if (!this.pool) {
      for (const [key, profile] of this.profiles) {
        if (key.startsWith(uidPrefix) || uidPrefix.startsWith(key)) return profile
      }
      return undefined
    }
    const result = await this.pool.query('SELECT * FROM user_profiles WHERE reporter_uid LIKE $1 OR $2 LIKE reporter_uid || \'%\' LIMIT 1', [uidPrefix + '%', uidPrefix])
    return result.rows[0]
  }
  async allProfiles(): Promise<ProfileRecord[]> {
    if (!this.pool) return [...this.profiles.values()]
    const result = await this.pool.query('SELECT * FROM user_profiles ORDER BY registered_at_ms DESC')
    return result.rows
  }
  async profilesForPhone(phone: string): Promise<ProfileRecord[]> {
    // A contact saves "+91 98765 43211" while that person registers
    // "9876543211". Compare the last 10 significant digits so the fan-out
    // still reaches the right account.
    const digits = String(phone ?? '').replace(/\D/g, '')
    if (digits.length < 6) return []
    const suffix = digits.slice(-10)
    if (!this.pool) return [...this.profiles.values()].filter(profile => String(profile.phone ?? '').replace(/\D/g, '').slice(-10) === suffix)
    const result = await this.pool.query(`SELECT * FROM user_profiles WHERE right(regexp_replace(phone, '\\D', '', 'g'), 10) = $1`, [suffix])
    return result.rows
  }
  async createNotifications(records: NotificationRecord[]): Promise<NotificationRecord[]> {
    const created: NotificationRecord[] = []
    for (const record of records) {
      if (this.notifications.has(record.notification_id)) continue
      if (this.pool) {
        const result = await this.pool.query(`INSERT INTO sos_notification_deliveries (notification_id, event_id, recipient_type, recipient_key, update_type, title, body, public_url, created_at_ms) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (notification_id) DO NOTHING RETURNING *`, [record.notification_id, record.event_id, record.recipient_type, record.recipient_key, record.update_type, record.title, record.body, record.public_url, record.created_at_ms])
        if (!result.rows[0]) continue
      }
      this.notifications.set(record.notification_id, record)
      created.push(record)
    }
    return created
  }
  async reserveSmsDelivery(record: SmsDeliveryRecord): Promise<SmsDeliveryRecord | undefined> {
    if (this.smsDeliveries.has(record.sms_delivery_id)) return undefined
    if (this.pool) {
      const result = await this.pool.query(`INSERT INTO sos_sms_deliveries (sms_delivery_id, event_id, recipient_phone, recipient_name, state, provider_message_sid, failure_reason, created_at_ms, completed_at_ms) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (sms_delivery_id) DO NOTHING RETURNING *`, [record.sms_delivery_id, record.event_id, record.recipient_phone, record.recipient_name, record.state, record.provider_message_sid, record.failure_reason, record.created_at_ms, record.completed_at_ms])
      if (!result.rows[0]) return undefined
    }
    this.smsDeliveries.set(record.sms_delivery_id, record)
    return record
  }
  async completeSmsDelivery(id: string, result: { state: 'sent' | 'failed'; providerMessageSid?: string; failureReason?: string }) {
    const current = this.smsDeliveries.get(id)
    if (!current) return undefined
    const next: SmsDeliveryRecord = { ...current, state: result.state, provider_message_sid: result.providerMessageSid ?? null, failure_reason: result.failureReason ?? null, completed_at_ms: Date.now() }
    this.smsDeliveries.set(id, next)
    if (this.pool) await this.pool.query('UPDATE sos_sms_deliveries SET state=$2, provider_message_sid=$3, failure_reason=$4, completed_at_ms=$5 WHERE sms_delivery_id=$1', [id, next.state, next.provider_message_sid, next.failure_reason, next.completed_at_ms])
    return next
  }
  async smsDeliveriesForEvent(eventId: string): Promise<SmsDeliveryRecord[]> {
    if (!this.pool) return [...this.smsDeliveries.values()].filter(record => record.event_id === eventId).sort((a, b) => a.created_at_ms - b.created_at_ms)
    const result = await this.pool.query('SELECT * FROM sos_sms_deliveries WHERE event_id=$1 ORDER BY created_at_ms ASC', [eventId])
    return result.rows
  }
  async notificationsFor(recipientKey: string): Promise<NotificationRecord[]> {
    if (!this.pool) return [...this.notifications.values()].filter(record => record.recipient_key === recipientKey).sort((a, b) => b.created_at_ms - a.created_at_ms)
    const result = await this.pool.query('SELECT * FROM sos_notification_deliveries WHERE recipient_key=$1 ORDER BY created_at_ms DESC', [recipientKey])
    return result.rows
  }
  async recipientKeysForEvent(eventId: string): Promise<{ recipient_type: NotificationRecord['recipient_type']; recipient_key: string }[]> {
    if (!this.pool) return [...this.notifications.values()].filter(record => record.event_id === eventId).map(record => ({ recipient_type: record.recipient_type, recipient_key: record.recipient_key }))
    const result = await this.pool.query('SELECT DISTINCT recipient_type, recipient_key FROM sos_notification_deliveries WHERE event_id=$1', [eventId])
    return result.rows
  }
  async createAuthorityResponse(record: AuthorityResponseRecord, idempotencyKey: string, requestHash: string): Promise<{ record?: AuthorityResponseRecord; replay: boolean; conflict: boolean }> {
    if (!this.pool) {
      const previous = this.authorityIdempotency.get(idempotencyKey)
      if (previous) {
        return { record: this.authorityResponses.get(previous.responseId), replay: previous.requestHash === requestHash, conflict: previous.requestHash !== requestHash }
      }
      this.authorityResponses.set(record.response_id, record)
      this.authorityIdempotency.set(idempotencyKey, { responseId: record.response_id, requestHash })
      return { record, replay: false, conflict: false }
    }
    const existing = await this.pool.query('SELECT response_id, request_hash FROM authority_response_idempotency WHERE idempotency_key=$1', [idempotencyKey])
    if (existing.rows[0]) {
      const row = existing.rows[0]
      const response = await this.pool.query('SELECT * FROM authority_responses WHERE response_id=$1', [row.response_id])
      return { record: response.rows[0], replay: row.request_hash === requestHash, conflict: row.request_hash !== requestHash }
    }
    const client = await this.pool.connect()
    try {
      await client.query('BEGIN')
      await client.query('INSERT INTO authority_responses (response_id,event_id,reply_to_event_id,site_id,destination_ephemeral_id,response_type,message_text,signed_payload,key_id,state,route_mode,return_hops,retry_count,created_at_ms,expires_at_ms,gateway_session_id,trace_id,original_trace_id) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18)', [record.response_id, record.event_id, record.reply_to_event_id ?? record.event_id, record.site_id, record.destination_ephemeral_id, record.response_type, record.message_text, record.signed_payload, record.key_id, record.state, record.route_mode, record.return_hops, record.retry_count, record.created_at_ms, record.expires_at_ms, record.gateway_session_id, record.trace_id, record.original_trace_id])
      await client.query('INSERT INTO authority_response_idempotency (idempotency_key,response_id,request_hash) VALUES ($1,$2,$3)', [idempotencyKey, record.response_id, requestHash])
      await client.query('COMMIT')
      return { record, replay: false, conflict: false }
    } catch (error) {
      await client.query('ROLLBACK')
      throw error
    } finally {
      client.release()
    }
  }

  async authorityResponse(id: string): Promise<AuthorityResponseRecord | undefined> {
    if (!this.pool) return this.authorityResponses.get(id)
    const result = await this.pool.query('SELECT * FROM authority_responses WHERE response_id=$1', [id])
    return result.rows[0]
  }

  /// The response ID is the deterministic tie-breaker for commands created
  /// in the same millisecond. A legacy numeric cursor remains valid, while a
  /// composite `created_at_ms:response_id` cursor makes paged polls lossless.
  async pendingGatewayCommands(gatewaySessionId: string, cursor: string | undefined, limit: number): Promise<AuthorityResponseRecord[]> {
    const match = cursor?.match(/^(0|[1-9][0-9]*)(?::([A-Za-z0-9-]+))?$/)
    const createdAfter = Number(match?.[1] ?? '0')
    const responseAfter = match?.[2]
    const afterCursor = (row: AuthorityResponseRecord) => row.created_at_ms > createdAfter
      || (responseAfter != null && row.created_at_ms === createdAfter && row.response_id > responseAfter)
    if (!this.pool) {
      return [...this.authorityResponses.values()]
        .filter(row => row.state === 'SIGNED' && afterCursor(row) && row.expires_at_ms > Date.now())
        .sort((a, b) => a.created_at_ms - b.created_at_ms || a.response_id.localeCompare(b.response_id))
        .slice(0, limit)
    }
    const result = responseAfter == null
      ? await this.pool.query('SELECT * FROM authority_responses WHERE state=$1 AND created_at_ms>$2 AND expires_at_ms>$3 ORDER BY created_at_ms ASC, response_id ASC LIMIT $4', ['SIGNED', createdAfter, Date.now(), limit])
      : await this.pool.query('SELECT * FROM authority_responses WHERE state=$1 AND (created_at_ms>$2 OR (created_at_ms=$2 AND response_id>$3)) AND expires_at_ms>$4 ORDER BY created_at_ms ASC, response_id ASC LIMIT $5', ['SIGNED', createdAfter, responseAfter, Date.now(), limit])
    return result.rows
  }

  async markGatewayReceived(id: string, gatewaySessionId: string, meshObjectId?: string) {
    const current = await this.authorityResponse(id)
    if (!current) return undefined
    if (current.gateway_session_id && current.gateway_session_id !== gatewaySessionId) return undefined
    if (current.state !== 'SIGNED' && current.state !== 'GATEWAY_RECEIVED' && current.state !== 'MESH_QUEUED') {
      return current.state === 'FORWARDING' || current.state === 'SENDER_DELIVERED' || current.state === 'RECEIPT_AT_DASHBOARD' ? current : undefined
    }
    const patch: Partial<AuthorityResponseRecord> = {
      state: 'MESH_QUEUED',
      gateway_session_id: gatewaySessionId,
      ...(meshObjectId ? { mesh_object_id: Number(meshObjectId) } : {}),
    }
    if (!this.pool) {
      const updated = { ...current, ...patch }
      this.authorityResponses.set(id, updated)
      return updated
    }
    const result = await this.pool.query('UPDATE authority_responses SET state=$2,gateway_session_id=$3,mesh_object_id=COALESCE($4,mesh_object_id) WHERE response_id=$1 AND (gateway_session_id IS NULL OR gateway_session_id=$3) AND state IN ($5,$6,$7) RETURNING *', [id, 'MESH_QUEUED', gatewaySessionId, meshObjectId ? Number(meshObjectId) : null, 'SIGNED', 'GATEWAY_RECEIVED', 'MESH_QUEUED'])
    return result.rows[0] ?? (await this.authorityResponse(id))
  }

  async updateAuthorityResponse(id: string, patch: Partial<Pick<AuthorityResponseRecord, 'state' | 'route_mode' | 'return_hops' | 'retry_count' | 'last_error'>>) {
    const current = await this.authorityResponse(id)
    if (!current) return undefined
    const nextState = patch.state
    if (nextState && nextState !== current.state) {
      const currentRank = authorityResponseStateRank[current.state]
      const nextRank = authorityResponseStateRank[nextState]
      // Progress is append-only. A duplicate update is idempotent, but a
      // late gateway packet must never move the dashboard backwards or turn
      // a terminal failure/receipt into an in-flight state.
      if (nextRank < currentRank || isAuthorityResponseTerminal(current.state)) return undefined
    }
    const safePatch = { ...patch, ...(patch.state ? { state: patch.state } : {}) }
    if (!this.pool) {
      const updated = { ...current, ...safePatch }
      this.authorityResponses.set(id, updated)
      return updated
    }
    const fields: string[] = []
    const values: unknown[] = [id]
    for (const [key, value] of Object.entries(safePatch)) {
      fields.push(`${key}=$${values.length + 1}`)
      values.push(value)
    }
    if (!fields.length) return current
    const result = await this.pool.query(`UPDATE authority_responses SET ${fields.join(',')} WHERE response_id=$1 RETURNING *`, values)
    return result.rows[0]
  }

  async recordAuthorityReceipt(receipt: AuthorityReceiptRecord) {
    if (!this.pool) {
      const existingReceipt = this.authorityReceipts.get(receipt.receipt_id)
      if (existingReceipt) {
        if (existingReceipt.response_id !== receipt.response_id) return undefined
        return this.authorityResponses.get(existingReceipt.response_id)
      }
      const response = this.authorityResponses.get(receipt.response_id)
      if (!response) return undefined
      this.authorityReceipts.set(receipt.receipt_id, receipt)
      const updated = { ...response, state: 'RECEIPT_AT_DASHBOARD' as const }
      this.authorityResponses.set(receipt.response_id, updated)
      return updated
    }
    const response = await this.pool.query('SELECT response_id FROM authority_responses WHERE response_id=$1', [receipt.response_id])
    if (!response.rows[0]) return undefined
    const existing = await this.pool.query('SELECT response_id FROM authority_response_receipts WHERE receipt_id=$1', [receipt.receipt_id])
    if (existing.rows[0] && existing.rows[0].response_id !== receipt.response_id) return undefined
    await this.pool.query('INSERT INTO authority_response_receipts (receipt_id,response_id,reply_to_event_id,sender_ephemeral_id,created_at_ms,received_at_ms) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (receipt_id) DO NOTHING', [receipt.receipt_id, receipt.response_id, receipt.reply_to_event_id, receipt.sender_ephemeral_id, receipt.created_at_ms, receipt.received_at_ms])
    const updated = await this.pool.query('UPDATE authority_responses SET state=$2 WHERE response_id=$1 RETURNING *', [receipt.response_id, 'RECEIPT_AT_DASHBOARD'])
    return updated.rows[0]
  }

}

export const store = new EventStore()
