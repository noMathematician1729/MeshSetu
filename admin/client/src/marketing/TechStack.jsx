import { useLayoutEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

const layers = [
  {
    title: 'Mobile app',
    tools: ['Flutter', 'Dart', 'Bluetooth Low Energy', 'Kotlin', 'SQLite', 'Sherpa-onnx', 'Store-and-forward SOS'],
  },
  {
    title: 'Backend layer',
    tools: ['Node.js', 'Express.js', 'TypeScript', 'REST APIs', 'WebSockets', 'Protocol Buffers', 'PostgreSQL', 'Neon PostgreSQL', 'SOS relay metrics','Internet uplink bridge'],
  },
  {
    title: 'Admin dashboard',
    tools: ['Next.js', 'React', 'TypeScript', 'Tailwind CSS', 'WebSocket live updates', 'OpenStreetMap', 'Incident status tracking', 'SOS transcript display', 'Voice-note transfer status', 'Audio playback'],
  },
];

export default function TechStack() {
  const sectionRef = useRef(null);

  useLayoutEffect(() => {
    const context = gsap.context(() => {
      const media = gsap.matchMedia();
      media.add('(prefers-reduced-motion: no-preference)', () => {
        const rows = gsap.utils.toArray('.tech-stack__card');
        const animation = gsap.from(rows, {
          x: (index) => -110 + index * 64,
          y: (index) => 90 - index * 38,
          opacity: 0,
          duration: 1.7,
          ease: 'power3.out',
          stagger: 0.24,
          scrollTrigger: {
            trigger: sectionRef.current,
            start: 'top 72%',
            once: true,
          },
        });
        return () => animation.kill();
      });
      return () => media.revert();
    }, sectionRef);

    return () => context.revert();
  }, []);

  return <section className="tech-stack" id="tech-stack" ref={sectionRef}>
    <div className="container">
      <div className="section-heading section-heading--split"><div><p className="section-label">Product foundation</p><h2>Tech stack</h2></div><div><p>Cutting Edge, Modern and Reliable</p><p>Three connected layers, ready to deliver.</p></div></div>
      <div className="tech-stack__grid">{layers.map((layer, index) => <article className="tech-stack__card" key={layer.title}>
        <span className="tech-stack__number">{String(index + 1).padStart(2, '0')}</span><h3>{layer.title}</h3>
        <div className="tech-stack__tools">{layer.tools.map((tool) => <span key={tool}>{tool}</span>)}</div>
      </article>)}</div>
    </div>
  </section>;
}
