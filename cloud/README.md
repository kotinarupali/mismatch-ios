# Mismatch Cloud Cards (V2)

Cloud-hosted card picking so players can join over **any internet connection** — no shared Wi‑Fi required.

## What this provides

- One HTTPS join link / QR code for all guests
- Real-time card claims (atomic, safe when two players pick at once)
- Same web UI as local QR mode (`/join/{token}`)
- Host iPhone syncs pick progress over the internet

## Deploy (Cloudflare Workers)

You need **Node.js** once. If `npm` is not installed (no Homebrew needed), use the project script:

```bash
cd cloud
chmod +x deploy.sh scripts/bootstrap-node.sh
./deploy.sh
```

That downloads Node into `../.tools/` automatically, installs dependencies, and deploys.

First deploy opens a browser for **Cloudflare login** (`wrangler login`). Create a free account at [cloudflare.com](https://dash.cloudflare.com/sign-up) if needed.

If deploy fails with error **10097**, ensure `wrangler.toml` uses `new_sqlite_classes` (required on Workers Free plan).

### Already have Node?

```bash
cd cloud
npm install
npm run deploy
```

If npm warns about **allow-scripts** (npm 11+), approve Wrangler’s dependencies once:

```bash
npm approve-scripts --allow-scripts-pending
```

The **audit vulnerabilities** message is dev-only tooling — safe to ignore for deploy. Do not run `npm audit fix --force` unless you know you need it.

### After deploy

1. Note the worker URL, e.g. `https://mismatch-cards.your-subdomain.workers.dev`
2. Edit `mismatch/Supporting/LocalNetworkInfo.plist`:

```xml
<key>MismatchCloudCardBaseURL</key>
<string>https://mismatch-cards.your-subdomain.workers.dev</string>
```

3. Rebuild the app in Xcode
4. In the lobby, choose **Cloud QR** under Distribution

## API

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/sessions` | Host creates session (player assignments) |
| `GET` | `/api/session/{token}` | Public snapshot for polling |
| `POST` | `/api/session/{token}` | Claim a card `{ playerId, cardIndex }` |
| `POST` | `/api/session/{token}/vote` | Guest submits vote `{ voterId, targetPlayerId }` |
| `POST` | `/api/sessions/{token}/voting` | Host opens/closes voting `{ hostKey, action, eliminatedPlayerIds }` |
| `POST` | `/api/sessions/{token}/delete` | Host ends session |
| `GET` | `/join/{token}` | Player web page |

## Local development

```bash
./deploy.sh --install-only   # install deps only
npm run dev
```

Use the printed `localhost` or tunnel URL as `MismatchCloudCardBaseURL` while testing.

## Security notes (V2)

- Session tokens are unguessable UUIDs
- Role/word secrets are only returned to the claiming player
- Sessions should be deleted when the game ends (host app calls delete)
- For production, add rate limiting and optional host auth on `POST /api/sessions`

## Cost

Cloudflare Workers free tier is sufficient for party-game usage (short-lived sessions, low traffic).
