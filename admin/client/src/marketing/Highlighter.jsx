import { useEffect, useRef, useState } from 'react';

export default function Highlighter({ action = 'highlight', color = '#fe1e34', children }) {
  const ref = useRef(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting) return;
      setIsVisible(true);
      observer.disconnect();
    }, { threshold: .7 });

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);

  return <span ref={ref} className={`highlighter highlighter--${action} ${isVisible ? 'highlighter--visible' : ''}`} style={{ '--highlighter-color': color }}>{children}</span>;
}
