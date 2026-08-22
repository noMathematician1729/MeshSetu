import Arrow from './Arrow';
import Highlighter from './Highlighter';
import SectionLabel from './SectionLabel';

export default function Hero() {
  return (
    <section className="hero" id="top">
      <div className="hero-ornament" aria-hidden="true">M</div>
      <div className="container hero-inner">
        <div className="hero-copy">
          <SectionLabel className="hero-eyebrow">MeshSetu / Offline emergency plan</SectionLabel>
          <h1>Help still <Highlighter action="underline" color="#fe1e34">moves</Highlighter><br />when <Highlighter action="highlight" color="#fe1e34">networks fail.</Highlighter></h1>
          <p className="hero-description">MeshSetu uses nearby Android phones to carry a structured SOS, short voice evidence, and scoped updates across a <Highlighter action="underline" color="#fe1e34">store-and-forward</Highlighter> Bluetooth Low Energy overlay when internet and cellular service are unavailable.</p>
          <div className="hero-actions">
            <a className="button button--signal" href="#simulation">Trace the relay <Arrow /></a>
            <a className="text-link" href="#how-it-works">How it works <Arrow /></a>
          </div>
        </div>
      </div>
      <div className="container hero-metrics" aria-label="MeshSetu system principles">
        <div className="hero-metric hero-metric--signal"><strong>OFFLINE</strong><span>Internet is optional</span></div>
        <div className="hero-metric"><strong>BLE</strong><span>Phone-to-phone relay</span></div>
        <div className="hero-metric"><strong>SOS</strong><span>Priority before routine traffic</span></div>
        <div className="hero-metric"><strong>LOCAL</strong><span>Gateway to control room</span></div>
      </div>
      <div className="hero-edge" aria-hidden="true"><span>01 / FIELD NETWORK</span><span>MESSAGE IN MOTION</span><span>SCROLL TO EXPLORE</span></div>
    </section>
  );
}
