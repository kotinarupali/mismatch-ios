#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT/.." && pwd)"
TOOLS="$PROJECT_ROOT/.tools"
NODE_VERSION="22.14.0"
ARCH="$(uname -m)"

case "$ARCH" in
  arm64) NODE_ARCH="darwin-arm64" ;;
  x86_64) NODE_ARCH="darwin-x64" ;;
  *)
    echo "Unsupported Mac architecture: $ARCH"
    exit 1
    ;;
esac

NODE_DIR="$TOOLS/node-v${NODE_VERSION}-${NODE_ARCH}"
NODE_BIN="$NODE_DIR/bin"

if [[ ! -x "$NODE_BIN/node" ]]; then
  mkdir -p "$TOOLS"
  TARBALL="node-v${NODE_VERSION}-${NODE_ARCH}.tar.gz"
  URL="https://nodejs.org/dist/v${NODE_VERSION}/${TARBALL}"

  echo "Downloading Node.js ${NODE_VERSION} for ${NODE_ARCH}..."
  curl -fsSL "$URL" -o "$TOOLS/$TARBALL"
  tar -xzf "$TOOLS/$TARBALL" -C "$TOOLS"
  rm "$TOOLS/$TARBALL"
  echo "Node installed at $NODE_DIR"
fi

export PATH="$NODE_BIN:$PATH"
echo "Using node $(node -v) / npm $(npm -v)"
