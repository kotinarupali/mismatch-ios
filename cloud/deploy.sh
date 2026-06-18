#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT/scripts/bootstrap-node.sh"

cd "$ROOT"
npm install

if [[ "${1:-}" == "--install-only" ]]; then
  echo "Dependencies installed. Run: npm run deploy"
  exit 0
fi

echo ""
echo "Deploying to Cloudflare Workers..."
echo "If this is your first time, a browser window will open for Cloudflare login."
echo ""
npm run deploy

echo ""
echo "Done. Copy the workers.dev URL into the app:"
echo "  mismatch/Supporting/LocalNetworkInfo.plist"
echo "  key: MismatchCloudCardBaseURL"
echo ""
echo "Then rebuild the app and choose Cloud QR in the lobby."
