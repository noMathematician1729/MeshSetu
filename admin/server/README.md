# MeshSetu control-room backend

Node/TypeScript replacement for the legacy FastAPI dashboard service.

```bash
cp .env.example .env
npm install
npm run build
npm start
```


Local development uses a fixed **non-production** P-256 authority key so that
QR event manifests and responder-update signatures remain compatible across
server restarts. Newly created local event manifests pin its public JWK before
they are QR-shared. In deployment, set both
`MESHSETU_AUTHORITY_PRIVATE_KEY_PEM_B64` and `MESHSETU_AUTHORITY_KEY_ID`, then
issue manifests containing the matching public JWK; never use the development
key in production.
The server listens on `0.0.0.0:8000`, exposes the versioned `/v1` API, and
preserves `/api/events` and `/ws` compatibility routes. The gateway posts raw
encrypted objects to `/v1/gateway/objects`; the server validates the
AES-256-GCM envelope, decodes `MeshEnvelope`, and only then persists the SOS
or verified voice evidence.

For the offline demo, run the repository root with Docker Compose:

```bash
docker compose up
```

Default local operator credentials are documented in `.env.example` and should
be replaced before a real deployment.
