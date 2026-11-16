#!/usr/bin/env sh
# Molar CLI installer
# Usage: curl -fsSL https://raw.githubusercontent.com/pratikranaa/molar-cli/main/install.sh | sh
# Or:    curl -fsSL https://raw.githubusercontent.com/pratikranaa/molar-cli/main/install.sh | sh -s -- --install-dir /custom/path

set -eu

REPO="pratikranaa/molar-cli"
COSIGN_IDENTITY_REGEXP='^https://github\.com/pratikranaa/Molar/\.github/workflows/release-cli\.yml@refs/tags/v'
COSIGN_ISSUER="https://token.actions.githubusercontent.com"
INSTALL_DIR="/usr/local/bin"

while [ $# -gt 0 ]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="$2"; shift 2 ;;
    --install-dir=*)
      INSTALL_DIR="${1#*=}"; shift ;;
    --force)
      shift ;;
    --version)
      VERSION="$2"; shift 2 ;;
    --version=*)
      VERSION="${1#*=}"; shift ;;
    *)
      echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin) PLAT_OS="darwin" ;;
  Linux)  PLAT_OS="linux" ;;
  *)
    echo "Unsupported OS: $OS" >&2
    echo "Please download manually from https://github.com/$REPO/releases" >&2
    exit 1 ;;
esac

case "$ARCH" in
  arm64|aarch64) PLAT_ARCH="arm64" ;;
  x86_64|amd64) PLAT_ARCH="x64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

BINARY_NAME="molar-${PLAT_OS}-${PLAT_ARCH}"
INSTALL_NAME="molar"

if [ -z "${VERSION:-}" ]; then
  # Only this explicitly pinned beta uses checksum-only verification.
  VERSION="v0.3.14"
fi

echo "→ Installing molar $VERSION for ${PLAT_OS}-${PLAT_ARCH}..."

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/${BINARY_NAME}"
if [ "$VERSION" = "v0.3.14" ]; then
  CHECKSUM_URL="https://github.com/$REPO/releases/download/$VERSION/SHA256SUMS"
else
  CHECKSUM_URL="${DOWNLOAD_URL}.sha256"
fi
BUNDLE_URL="${DOWNLOAD_URL}.cosign.bundle"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TMP_BIN="$TMP_DIR/$BINARY_NAME"
TMP_SHA="$TMP_DIR/${BINARY_NAME}.sha256"
TMP_BUNDLE="$TMP_DIR/${BINARY_NAME}.cosign.bundle"

if [ "$VERSION" != "v0.3.14" ] && ! command -v cosign >/dev/null 2>&1; then
  echo "Error: cosign is required to verify the Molar release signature." >&2
  echo "Install it from https://docs.sigstore.dev/cosign/system_config/installation/ and retry." >&2
  exit 1
fi

echo "→ Downloading binary..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL --progress-bar -o "$TMP_BIN" "$DOWNLOAD_URL"
  curl -fsSL -o "$TMP_SHA" "$CHECKSUM_URL"
  if [ "$VERSION" != "v0.3.14" ]; then curl -fsSL -o "$TMP_BUNDLE" "$BUNDLE_URL"; fi
else
  wget -q --show-progress -O "$TMP_BIN" "$DOWNLOAD_URL" 2>&1 || wget -qO "$TMP_BIN" "$DOWNLOAD_URL"
  wget -qO "$TMP_SHA" "$CHECKSUM_URL"
  if [ "$VERSION" != "v0.3.14" ]; then wget -qO "$TMP_BUNDLE" "$BUNDLE_URL"; fi
fi

echo "→ Verifying checksum..."
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$TMP_BIN" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "$TMP_BIN" | awk '{print $1}')"
else
  echo "Error: sha256sum or shasum is required; refusing an unverified install." >&2
  exit 1
fi

if [ "$VERSION" = "v0.3.14" ]; then
  EXPECTED="$(awk -v name="$BINARY_NAME" '$2 == name {print $1; count++} END {if (count != 1) exit 1}' "$TMP_SHA")"
else
  EXPECTED="$(awk '{print $1}' "$TMP_SHA")"
fi
case "$EXPECTED" in *[!0-9a-f]*|'') echo "Error: invalid checksum" >&2; exit 1;; esac
if [ "${#EXPECTED}" -ne 64 ]; then echo "Error: invalid checksum" >&2; exit 1; fi
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "Error: checksum mismatch!" >&2
  echo "  expected: $EXPECTED" >&2
  echo "  got:      $ACTUAL" >&2
  exit 1
fi
echo "  ✓ sha256: $ACTUAL"

if [ "$VERSION" = "v0.3.14" ]; then
  echo "  Note: unsigned beta; SHA-256 verifies download integrity only."
else
  echo "→ Verifying keyless signature..."
  cosign verify-blob \
    --bundle "$TMP_BUNDLE" \
    --certificate-identity-regexp "$COSIGN_IDENTITY_REGEXP" \
    --certificate-oidc-issuer "$COSIGN_ISSUER" \
    "$TMP_BIN" >/dev/null
  echo "  ✓ Sigstore identity: pratikranaa/Molar release-cli.yml"
fi

chmod +x "$TMP_BIN"
DEST="$INSTALL_DIR/$INSTALL_NAME"
mkdir -p "$INSTALL_DIR"
if [ -f "$DEST" ]; then
  PREV="$INSTALL_DIR/$INSTALL_NAME.previous"
  mv "$DEST" "$PREV" 2>/dev/null || true
  echo "  ↩  previous version saved as $PREV"
fi
mv "$TMP_BIN" "$DEST"
echo "  ✓ Installed to $DEST"
echo ""

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo "Note: $INSTALL_DIR is not in your PATH."
  echo "Add this to your shell profile:"
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
  echo ""
fi

"$DEST" --version && echo "" && echo "✓ molar is ready. Run 'molar --help' to get started."
