#!/usr/bin/env sh
# Molar CLI installer
# Usage: curl -fsSL https://raw.githubusercontent.com/pratikranaa/molar-cli/main/install.sh | sh
# Or:    curl -fsSL https://raw.githubusercontent.com/pratikranaa/molar-cli/main/install.sh | sh -s -- --install-dir /custom/path
#
# What it does:
#   1. Detects OS/arch
#   2. Downloads the matching binary from GitHub Releases
#   3. Verifies the SHA-256 checksum
#   4. Verifies the Sigstore signature except for the explicitly listed unsigned betas (UNSIGNED_BETAS)
#   5. Installs to /usr/local/bin/molar (or --install-dir)
#   6. Keeps the previous version as molar.previous for rollback
#
# Requirements: curl (or wget), sha256sum (or shasum on macOS); cosign for signed releases
# No root required if --install-dir is writable by the current user.

set -eu

REPO="pratikranaa/molar-cli"
COSIGN_IDENTITY_REGEXP='^https://github\.com/pratikranaa/Molar/\.github/workflows/release-cli\.yml@refs/tags/v'
COSIGN_ISSUER="https://token.actions.githubusercontent.com"
INSTALL_DIR="/usr/local/bin"
FORCE=""

# ── Parse args ───────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="$2"; shift 2 ;;
    --install-dir=*)
      INSTALL_DIR="${1#*=}"; shift ;;
    --force)
      FORCE="1"; shift ;;
    --version)
      VERSION="$2"; shift 2 ;;
    --version=*)
      VERSION="${1#*=}"; shift ;;
    *)
      echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── Detect platform ───────────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin) PLAT_OS="darwin" ;;
  Linux)  PLAT_OS="linux"  ;;
  *)
    echo "Unsupported OS: $OS" >&2
    echo "Please download manually from https://github.com/$REPO/releases" >&2
    exit 1
    ;;
esac

case "$ARCH" in
  arm64|aarch64) PLAT_ARCH="arm64" ;;
  x86_64|amd64)  PLAT_ARCH="x64"   ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

BINARY_NAME="molar-${PLAT_OS}-${PLAT_ARCH}"
INSTALL_NAME="molar"

# ── Resolve version ───────────────────────────────────────────────────────────
# Unsigned beta releases verified by SHA256SUMS only; every other version needs its cosign signature.
UNSIGNED_BETAS="v0.3.14 v0.3.15"
is_unsigned_beta() { case " $UNSIGNED_BETAS " in *" $1 "*) return 0 ;; esac; return 1; }

if [ -z "${VERSION:-}" ]; then
  # The unsigned beta is an explicitly pinned exception; all other versions
  # continue to require the release workflow's Sigstore identity below.
  VERSION="v0.3.15"
fi

echo "→ Installing molar $VERSION for ${PLAT_OS}-${PLAT_ARCH}..."

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/${BINARY_NAME}"
if is_unsigned_beta "$VERSION"; then
  CHECKSUM_URL="https://github.com/$REPO/releases/download/$VERSION/SHA256SUMS"
else
  CHECKSUM_URL="${DOWNLOAD_URL}.sha256"
fi
BUNDLE_URL="${DOWNLOAD_URL}.cosign.bundle"

# ── Download ──────────────────────────────────────────────────────────────────
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TMP_BIN="$TMP_DIR/$BINARY_NAME"
TMP_SHA="$TMP_DIR/${BINARY_NAME}.sha256"
TMP_BUNDLE="$TMP_DIR/${BINARY_NAME}.cosign.bundle"

if ! is_unsigned_beta "$VERSION" && ! command -v cosign >/dev/null 2>&1; then
  echo "Error: cosign is required to verify the Molar release signature." >&2
  echo "Install it from https://docs.sigstore.dev/cosign/system_config/installation/ and retry." >&2
  exit 1
fi

echo "→ Downloading binary..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL --progress-bar -o "$TMP_BIN" "$DOWNLOAD_URL"
  curl -fsSL -o "$TMP_SHA" "$CHECKSUM_URL"
  if ! is_unsigned_beta "$VERSION"; then curl -fsSL -o "$TMP_BUNDLE" "$BUNDLE_URL"; fi
else
  wget -q --show-progress -O "$TMP_BIN" "$DOWNLOAD_URL" 2>&1 || wget -qO "$TMP_BIN" "$DOWNLOAD_URL"
  wget -qO "$TMP_SHA" "$CHECKSUM_URL"
  if ! is_unsigned_beta "$VERSION"; then wget -qO "$TMP_BUNDLE" "$BUNDLE_URL"; fi
fi

# ── Verify checksum ───────────────────────────────────────────────────────────
echo "→ Verifying checksum..."
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$TMP_BIN" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "$TMP_BIN" | awk '{print $1}')"
else
  echo "Error: sha256sum or shasum is required; refusing an unverified install." >&2
  exit 1
fi

if is_unsigned_beta "$VERSION"; then
  EXPECTED="$(awk -v name="$BINARY_NAME" '$2 == name {print $1; count++} END {if (count != 1) exit 1}' "$TMP_SHA")"
else
  EXPECTED="$(awk '{print $1}' "$TMP_SHA")"
fi
case "$EXPECTED" in *[!0-9a-f]*|'') echo "Error: invalid checksum" >&2; exit 1;; esac
if [ "${#EXPECTED}" -ne 64 ]; then echo "Error: invalid checksum" >&2; exit 1; fi
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "Error: checksum mismatch!" >&2
  echo "  expected: $EXPECTED" >&2
  echo "  got:      $ACTUAL"   >&2
  echo "The download may be corrupted. Please try again." >&2
  exit 1
fi
echo "  ✓ sha256: $ACTUAL"

if is_unsigned_beta "$VERSION"; then
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

# ── Install ───────────────────────────────────────────────────────────────────
DEST="$INSTALL_DIR/$INSTALL_NAME"

mkdir -p "$INSTALL_DIR"

# Keep previous version for rollback
if [ -f "$DEST" ]; then
  PREV="$INSTALL_DIR/$INSTALL_NAME.previous"
  mv "$DEST" "$PREV" 2>/dev/null || true
  echo "  ↩  previous version saved as $PREV"
fi

# Atomic install (rename is atomic on POSIX within the same filesystem)
mv "$TMP_BIN" "$DEST"

echo "  ✓ Installed to $DEST"
echo ""

# ── Post-install check ────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo "Note: $INSTALL_DIR is not in your PATH."
  echo "Add this to your shell profile:"
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
  echo ""
fi

"$DEST" --version && echo "" && echo "✓ molar is ready. Run 'molar --help' to get started."
