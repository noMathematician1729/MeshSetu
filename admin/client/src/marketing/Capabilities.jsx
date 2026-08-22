function RoomsVisual() {
  return <svg className="rooms-visual" viewBox="0 0 520 300" fill="none" aria-hidden="true">
    <g className="rooms-room"><rect x="65" y="36" width="390" height="228" rx="28" /><circle cx="91" cy="62" r="5" /></g>
    <path className="rooms-path" d="m150 154 110 35 108-35M150 154l110-53 108 53M260 101v88" />
    <path className="rooms-path rooms-path--faint" d="M91 62h338M91 238h338" />
    <g className="rooms-person rooms-person--one"><circle cx="150" cy="133" r="18" /><path d="M120 189c7-24 17-35 30-35s23 11 30 35" /><circle cx="150" cy="131" r="6" /></g>
    <g className="rooms-person rooms-person--two"><circle cx="260" cy="168" r="18" /><path d="M230 224c7-24 17-35 30-35s23 11 30 35" /><circle cx="260" cy="166" r="6" /></g>
    <g className="rooms-person rooms-person--three"><circle cx="368" cy="133" r="18" /><path d="M338 189c7-24 17-35 30-35s23 11 30 35" /><circle cx="368" cy="131" r="6" /></g>
  </svg>;
}

function GestureVisual() {
  return <svg className="gesture-visual" viewBox="0 0 520 310" fill="none" aria-hidden="true">
    <path className="gesture-orbit" d="M92 234c14-102 78-162 174-162 81 0 141 39 167 104" />
    <g className="gesture-phone"><rect x="190" y="30" width="145" height="260" rx="27" /><rect x="202" y="56" width="121" height="206" rx="14" /><rect className="gesture-sos-screen" x="206" y="60" width="113" height="198" rx="11" /><path d="M247 44h32" /><rect x="219" y="86" width="87" height="25" rx="6" /><circle className="gesture-sos-mark" cx="262" cy="172" r="38" /><path className="gesture-sos-check" d="m242 172 13 13 29-31" /></g>
    <g className="gesture-button"><rect x="181" y="105" width="10" height="36" rx="5" /><path d="M168 112v22" /></g>
    <circle className="gesture-press gesture-press--one" cx="181" cy="123" r="15" /><circle className="gesture-press gesture-press--two" cx="181" cy="123" r="15" /><circle className="gesture-press gesture-press--three" cx="181" cy="123" r="15" />
  </svg>;
}

function OfflineVisual() {
  return <svg className="offline-visual" viewBox="0 0 440 150" fill="none" aria-hidden="true">
    <rect className="offline-device" x="36" y="78" width="42" height="55" rx="7" /><path className="offline-device" d="M48 89h18M54 121h6" /><rect className="offline-device" x="362" y="78" width="42" height="55" rx="7" /><path className="offline-device" d="M374 89h18M380 121h6" />
    <circle className="offline-packet" cx="78" cy="104" r="6"><animateMotion dur="8.2s" repeatCount="indefinite" calcMode="spline" keySplines=".37 0 .63 1" path="M0 0Q152-176 305 0" /></circle><path className="offline-no-wifi" d="M59 48c12-12 30-12 42 0M66 55c8-8 20-8 28 0M77 62c2-2 5-2 7 0M52 40l53 29" />
  </svg>;
}

function VoiceVisual() {
  return <svg className="voice-visual" viewBox="0 0 440 150" fill="none" aria-hidden="true">
    <circle className="voice-mic-ring" cx="83" cy="76" r="42" /><path className="voice-mic" d="M83 49a11 11 0 0 0-11 11v22a11 11 0 0 0 22 0V60a11 11 0 0 0-11-11Zm-20 30a20 20 0 0 0 40 0M83 99v16M68 115h30" />
    <g className="voice-wave"><path d="M160 77v-8M178 77V55M196 77V43M214 77V58M232 77V35M250 77V51M268 77V44M286 77V62M304 77V52M322 77V67" /></g>
    <path className="voice-track" d="M157 106h168" /><circle className="voice-progress" cx="160" cy="106" r="5" />
  </svg>;
}

export default function Capabilities() {
  return <section className="capabilities section-paper" id="capabilities"><div className="container"><div className="section-heading capabilities-intro"><h2>Features</h2><p>All-in-one SOS, completely ready when it matters.</p></div><div className="capability-bento">
    <article className="capability-panel capability-panel--large capability-panel--rooms"><h3 className="capability-panel__title">Personalised rooms</h3><RoomsVisual /></article>
    <article className="capability-panel capability-panel--small capability-panel--offline" id="demo"><h3 className="capability-panel__title">No Wi-Fi — no problem</h3><OfflineVisual /></article>
    <article className="capability-panel capability-panel--small capability-panel--voice"><h3 className="capability-panel__title">Voice SOS</h3><VoiceVisual /></article>
    <article className="capability-panel capability-panel--large capability-panel--gesture"><h3 className="capability-panel__title">Gesture control</h3><GestureVisual /></article>
  </div></div></section>;
}
