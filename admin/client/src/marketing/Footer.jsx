import Logo from './Logo';

export default function Footer() {
  return <footer className="site-footer section-dark"><div className="container footer-grid"><div><Logo inverted /><p>Offline emergency communication,<br />relayed phone to phone.</p></div><div className="footer-links"><a href="#how-it-works">How it works</a><a href="#tech-stack">Technical overview</a><a href="https://github.com/noMathematician1729/MeshSetu" target="_blank" rel="noreferrer">Source code</a><a href="#top">Back to top</a></div><div className="footer-status"><span className="status-dot" /> Android-first hackathon prototype</div></div><div className="container footer-bottom"><span>© 2026 MeshSetu</span><span>Application-layer BLE overlay · Not yet a production emergency service</span></div></footer>;
}
