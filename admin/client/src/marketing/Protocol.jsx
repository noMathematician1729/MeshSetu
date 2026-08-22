import { useLayoutEffect, useRef, useState } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Highlighter from './Highlighter';
import SectionLabel from './SectionLabel';

gsap.registerPlugin(ScrollTrigger);

const packetBytes = [
  { value: '02', field: 'version', label: 'Protocol version', bits: '00000010', detail: 'Defines the packet format. A relay uses this value to decode the SOS object with the correct protocol version.' },
  { value: '41', field: 'flags', label: 'SOS flags', bits: '01000001', detail: 'Carries the emergency state and category so urgent SOS traffic can be recognised immediately.' },
  { value: 'A7', field: 'uid[0]', label: 'Device UID · 1', bits: '10100111', detail: 'The first byte of a pseudonymous device identifier. It helps the mesh recognise a signal without broadcasting personal details.' },
  { value: '3F', field: 'uid[1]', label: 'Device UID · 2', bits: '00111111', detail: 'Part of the identifier block that lets a gateway associate relayed fragments with the same originating device.' },
  { value: 'C2', field: 'uid[2]', label: 'Device UID · 3', bits: '11000010', detail: 'A compact UID field that supports deduplication, so the same SOS is not repeatedly processed.' },
  { value: '8E', field: 'uid[3]', label: 'Device UID · 4', bits: '10001110', detail: 'Continues the anonymous identifier block used to recognise a repeated signal across nearby relay phones.' },
  { value: '19', field: 'uid[4]', label: 'Device UID · 5', bits: '00011001', detail: 'Helps a gateway distinguish the SOS origin from the device currently carrying the packet.' },
  { value: 'D4', field: 'uid[5]', label: 'Device UID · 6', bits: '11010100', detail: 'Completes the six-byte identity block, keeping the on-air packet compact and privacy-aware.' },
  { value: '07', field: 'sequence', label: 'Sequence counter', bits: '00000111', detail: 'Changes for each broadcast burst so relays can suppress duplicate packets while preserving a new SOS.' },
  { value: 'B3', field: 'crc8', label: 'CRC8 checksum', bits: '10110011', detail: 'A lightweight integrity check over the preceding bytes. Corrupted packets are discarded before they trigger a response.' },
];

function GattVisual() {
  return <svg className="protocol-gatt-visual" viewBox="0 0 360 144" role="img" aria-label="A compact SOS packet travelling between two nearby phones">
    <g className="protocol-gatt-phone protocol-gatt-phone--left"><rect x="45" y="36" width="48" height="78" rx="9" /><rect x="51" y="45" width="36" height="54" rx="4" /><path d="M62 106h14" /></g>
    <g className="protocol-gatt-phone protocol-gatt-phone--right"><rect x="267" y="36" width="48" height="78" rx="9" /><rect x="273" y="45" width="36" height="54" rx="4" /><path d="M284 106h14" /></g>
    {[0, -1.6, -3.2].map((begin) => <circle className="protocol-gatt-packet" cx="91" cy="75" r="5" key={begin}><animateMotion dur="4.8s" begin={`${begin}s`} repeatCount="indefinite" path="M0 0Q89-100 178 0" /></circle>)}
  </svg>;
}

function TriageVisual() {
  return <svg className="protocol-triage-visual" viewBox="0 0 520 240" role="img" aria-label="SOS 1 and SOS 2 converging at the control centre, then branching to two authorities">
    <defs><pattern id="triage-grid" width="12" height="12" patternUnits="userSpaceOnUse"><path d="M12 0H0V12" fill="none" stroke="rgba(252,252,252,.08)" strokeWidth="1" /></pattern></defs>
    <rect width="520" height="240" fill="url(#triage-grid)" />
    <g className="protocol-triage-lines"><path d="M75 60H188L236 111" /><path d="M75 180H178L236 129" /><path d="M284 111L354 40H432" /><path d="M284 129L330 180H432" /></g>
    <g className="protocol-triage-icon protocol-triage-icon--people"><circle cx="45" cy="52" r="7" /><circle cx="60" cy="55" r="5" /><path d="M32 76c1-11 7-17 13-17s12 6 13 17M51 77c1-8 5-13 10-13s9 5 10 13" /><text className="protocol-triage-label" x="52" y="96" textAnchor="middle">SOS 1</text></g>
    <g className="protocol-triage-icon protocol-triage-icon--people"><circle cx="45" cy="172" r="7" /><circle cx="60" cy="175" r="5" /><path d="M32 196c1-11 7-17 13-17s12 6 13 17M51 197c1-8 5-13 10-13s9 5 10 13" /><text className="protocol-triage-label" x="52" y="216" textAnchor="middle">SOS 2</text></g>
    <g className="protocol-triage-icon protocol-triage-icon--router"><path d="M241 114l-7-18M279 114l7-18" /><rect x="236" y="113" width="48" height="26" rx="4" /><circle cx="247" cy="126" r="1.7" /><circle cx="255" cy="126" r="1.7" /><path d="M265 126h10" /><text className="protocol-triage-label" x="260" y="157" textAnchor="middle">CONTROL</text></g>
    <g className="protocol-triage-icon protocol-triage-icon--badge"><path d="M466 20l17 7v14c0 12-7 21-17 26-10-5-17-14-17-26V27l17-7Z" /><path d="m466 31 3.3 6.5 7.2 1-5.2 5 1.2 7-6.5-3.3-6.5 3.3 1.2-7-5.2-5 7.2-1 3.3-6.5Z" /><text className="protocol-triage-label" x="466" y="82" textAnchor="middle">POLICE</text></g>
    <g className="protocol-triage-icon protocol-triage-icon--hospital"><path d="M466 165v30M451 180h30" /><text className="protocol-triage-label" x="466" y="216" textAnchor="middle">HOSPITAL</text></g>
  </svg>;
}

export default function Protocol() {
  const sectionRef = useRef(null);
  const [selectedByte, setSelectedByte] = useState(null);

  useLayoutEffect(() => {
    const context = gsap.context(() => {
      const media = gsap.matchMedia();
      media.add('(prefers-reduced-motion: no-preference)', () => {
        const timeline = gsap.timeline({
          scrollTrigger: {
            trigger: sectionRef.current,
            start: 'top 72%',
            once: true,
          },
        });

        timeline
          .from('.protocol-byte', { x: -100, opacity: 0, duration: 1.55, ease: 'power3.out', stagger: 0.2 })
          .from('.protocol-card', { x: 120, opacity: 0, duration: 1.45, ease: 'power3.out', stagger: 0.28 }, '-=0.85');

        return () => timeline.kill();
      });
      return () => media.revert();
    }, sectionRef);

    return () => context.revert();
  }, []);

  return (
    <section className="protocol" id="protocol" ref={sectionRef}>
      <div className="container">
        <header className="protocol__heading">
          <div><SectionLabel light>Protocol</SectionLabel><h2>Small packets.<br /><em>Clear intent.</em></h2></div>
          <p>Every SOS is shaped into a <Highlighter action="highlight" color="#fe1e34">compact relay object</Highlighter> before it moves through the mesh. The packet stays small; the signal stays useful.</p>
        </header>

        <div className="protocol__stage">
          <div className="protocol-byte-flow" aria-label="SOS packet bytes moving through the mesh">
            <div className="protocol-stream__caption"><span>ENCODED SOS PACKET</span><i>10 BYTES</i></div>
            <div className="protocol-byte-row-wrap"><div className="protocol-byte-row">{packetBytes.map((byte, index) => <button type="button" className={`protocol-byte ${index % 2 ? 'protocol-byte--muted' : 'protocol-byte--signal'} ${selectedByte === index ? 'protocol-byte--active' : ''}`} key={byte.value} onClick={() => setSelectedByte(selectedByte === index ? null : index)} aria-pressed={selectedByte === index} aria-label={`Explain byte ${index + 1}: ${byte.label}`}><small>BYTE {String(index).padStart(2, '0')}</small><strong>0x{byte.value}</strong><span>{byte.field}</span></button>)}</div></div>
            <div className="protocol-stream__line" aria-hidden="true"><i /></div>
            <div className="protocol-stream__meta"><span>origin</span><span>relay-ready object</span><span>gateway</span></div>
            <div className={`protocol-byte-detail ${selectedByte !== null ? 'protocol-byte-detail--open' : ''}`} aria-live="polite">{selectedByte === null ? <span>Tap a byte to inspect its role in the packet.</span> : <><div className="protocol-byte-detail__head"><small>BYTE {String(selectedByte).padStart(2, '0')} · 0x{packetBytes[selectedByte].value}</small><strong>{packetBytes[selectedByte].label}</strong></div><div className="protocol-bit-row" aria-label={`Bit value ${packetBytes[selectedByte].bits}`}>{packetBytes[selectedByte].bits.split('').map((bit, index) => <i className={bit === '1' ? 'protocol-bit--on' : ''} key={`${bit}-${index}`}>{bit}</i>)}<span>MSB → LSB</span></div><p>{packetBytes[selectedByte].detail}</p></>}</div>
          </div>

          <div className="protocol-cards">
            <article className="protocol-card protocol-card--gatt"><span>01 / BLE TRANSPORT</span><h3>GATT relay</h3><p>When another phone enters range, it receives the compact SOS through a Bluetooth characteristic, holds it locally, and passes it safely to the next reachable peer.</p><GattVisual /><div><b>WRITE</b><i>→</i><b>NOTIFY</b></div></article>
            <article className="protocol-card protocol-card--triage"><span>02 / RESPONSE LAYER</span><h3>Local triage</h3><p>At the control centre, the SOS type, urgency, and available context determine where the signal goes next — toward the right authority or the team already coordinating the event.</p><TriageVisual /></article>
          </div>
        </div>
      </div>
    </section>
  );
}
