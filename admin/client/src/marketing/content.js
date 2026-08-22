export const capabilities = [
  { number: '01', title: 'Offline BLE relay', text: 'An application-layer, store-and-forward BLE overlay lets participating phones extend the path.', tone: 'red' },
  { number: '02', title: 'Structured SOS + priority', text: 'Incident type, urgency, hazards, zone, and evidence travel ahead of lower-priority traffic.', tone: 'yellow' },
  { number: '03', title: 'Short voice evidence', text: 'Bounded voice notes are compressed, chunked, relayed, and checked before playback.', tone: 'teal' },
  { number: '04', title: 'Scoped Rooms', text: 'Public alerts, zones, medical teams, and responders communicate through role-aware channels.', tone: 'cream' },
  { number: '05', title: 'Local intelligence', text: 'On-device speech-to-text and conservative triage support responders, with visible uncertainty.', tone: 'blue' },
  { number: '06', title: 'Control-room view', text: 'Operators can see priority, transcript state, zone, hop count, latency, and voice completeness.', tone: 'orange' },
];

export const steps = [
  { title: 'Onboarding', text: 'Open MeshSetu once to create a lightweight local profile. Your device is ready to participate in a nearby response network before an emergency begins.' },
  { title: 'Join a room or event', text: 'When relevant, optionally join a trusted room or event. This gives the people around you a shared local context without making it a requirement to send an SOS.' },
  { title: 'Choose your SOS', text: 'Choose the fastest way to explain what is happening: a general SOS, a short voice SOS, or a text SOS. The essential structured signal is saved first.' },
  { title: 'BLE carries it onward', text: 'If the internet is unavailable, nearby phones carry the encrypted message onward over Bluetooth Low Energy. Each relay stores it briefly, then passes it toward a gateway.' },
  { title: 'Control room reached', text: 'When the signal reaches a connected gateway, the local control room receives the verified SOS with the details responders need to act.' },
];

export const demoStages = [
  { label: 'ORIGIN DEVICE', title: 'SOS saved locally', detail: 'The structured report is committed to the phone before it tries to travel.', color: 'red' },
  { label: 'NEARBY PHONE', title: 'BLE relay picks it up', detail: 'A participating device stores the encrypted object and carries it to the next hop.', color: 'yellow' },
  { label: 'GATEWAY DEVICE', title: 'Local handoff confirmed', detail: 'A gateway phone bridges the verified incident to the control-room dashboard.', color: 'teal' },
  { label: 'CONTROL ROOM', title: 'Responder sees the signal', detail: 'Priority, zone uncertainty, hop count, and delivery state become actionable context.', color: 'blue' },
];
