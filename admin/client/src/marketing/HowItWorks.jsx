import { useLayoutEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { steps } from './content.js';
import SectionLabel from './SectionLabel';

gsap.registerPlugin(ScrollTrigger);

export default function HowItWorks() {
  const journeyRef = useRef(null);
  const viewportRef = useRef(null);
  const trackRef = useRef(null);

  useLayoutEffect(() => {
    const context = gsap.context(() => {
      const media = gsap.matchMedia();
      media.add('(min-width: 681px)', () => {
        const distance = () => Math.max(0, trackRef.current.scrollWidth - viewportRef.current.clientWidth);
        const journey = gsap.to(trackRef.current, {
          x: () => -distance(),
          ease: 'none',
          scrollTrigger: {
            trigger: journeyRef.current,
            start: 'top top',
            end: () => `+=${distance()}`,
            pin: viewportRef.current,
            scrub: 1.4,
            invalidateOnRefresh: true,
          },
        });
        return () => journey.kill();
      });
      return () => media.revert();
    }, journeyRef);
    return () => context.revert();
  }, []);

  return (
    <section className="how section-yellow" id="how-it-works" ref={journeyRef}>
      <div className="how-journey__viewport" ref={viewportRef}><div className="how-journey__track" ref={trackRef}>
        <header className="how-journey__intro"><SectionLabel>How it works</SectionLabel><h2>One SOS.<br /><em>Every step.</em></h2><p>Scroll down to trace how one signal moves from a phone in the field to the people ready to respond.</p><span>Scroll to follow the signal <b>↓</b></span></header>
        {steps.map((step) => <article className="journey-step" key={step.title}><div><h3>{step.title}</h3><p>{step.text}</p></div></article>)}
        <div className="how-journey__end" aria-hidden="true" />
      </div></div>
    </section>
  );
}
