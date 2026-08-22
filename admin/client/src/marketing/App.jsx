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

export default function App() {
  const scrollToSection = (event) => {
    const link = event.target.closest('a[href^="#"]');
    const target = link?.getAttribute('href');
    const section = target && event.currentTarget.querySelector(target);

    if (!section) return;

    event.preventDefault();
    section.scrollIntoView({
      behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth',
      block: 'start',
    });
  };

  return <div onClick={scrollToSection}><Header /><main><Hero /><HowItWorks /><MeshSimulation /><Capabilities /><Safety /><TechStack /><Architecture /><Interfaces /></main><Footer /></div>;
}
