import { gsap } from 'gsap';
import { ScrollToPlugin } from 'gsap/ScrollToPlugin';
import Architecture from './Architecture';
import Capabilities from './Capabilities';
import Footer from './Footer';
import Header from './Header';
import Hero from './Hero';
import HowItWorks from './HowItWorks';
import Interfaces from './Interfaces';
import MeshSimulation from './MeshSimulation';
import Safety from './Safety';
import TechStack from './TechStack';

gsap.registerPlugin(ScrollToPlugin);

export default function App() {
  const scrollToSection = (event) => {
    const link = event.target.closest('a[href^="#"]');
    const target = link?.getAttribute('href');
    const section = target && event.currentTarget.querySelector(target);

    if (!section) return;

    event.preventDefault();
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      section.scrollIntoView({ behavior: 'auto', block: 'start' });
      return;
    }

    gsap.to(window, {
      duration: 1.35,
      ease: 'power3.inOut',
      overwrite: 'auto',
      scrollTo: { y: section, offsetY: 96, autoKill: true },
    });
  };

  return <div onClick={scrollToSection}><Header /><main><Hero /><HowItWorks /><MeshSimulation /><Capabilities /><Safety /><TechStack /><Architecture /><Interfaces /></main><Footer /></div>;
}
