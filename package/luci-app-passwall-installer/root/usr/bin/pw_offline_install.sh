
#!/bin/sh
# Passwall offline one-click installer (LuCI wrapper)
# Usage: pw_offline_install.sh [23|24]
# Log:   /tmp/pw_installer.log (handled by LuCI)

set -eu

LOG=/tmp/pw_installer.log
: > "$LOG"

log() { printf '%s %s\n' "[$(date +%H:%M:%S)]" "$*" | tee -a "$LOG" ; }

# ---- CONFIG: your repo with parts + ipk helpers ----
OWNER="misaghmunchen"
REPO="passwall_offline_files"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH"
# parts: passwall.part.000..007  +  SHA256SUMS.txt  +  ipk/{bash,libnettle8,libgmp10}.ipk
PARTS="000 001 002 003 004 005 006 007"

# Select bundle version by arg (23|24) – only affects which repo subfolder to install from
VER="${1:-23}"           # "23" -> 23.05 repo ; "24" -> 24.10.2 repo
REPO_SUB="23.05/repo"
[ "$VER" = "24" ] && REPO_SUB="24.10.2/repo"

# workspace
BASE="/root/passwall_tmp"
DL="$BASE/dl"
OUT="$BASE/passwall_offline_bundle"

cleanup() {
  rm -rf "$DL"
}
trap cleanup EXIT

mkdir -p "$DL" "$OUT"

log "Starting offline installer (target repo: $REPO_SUB) ..."
log "Downloading SHA256SUMS ..."
if ! wget -q -O "$DL/SHA256SUMS.txt" "$RAW/SHA256SUMS.txt" ; then
  log "WARN: cannot fetch SHA256SUMS.txt (will continue without strict check)"
fi

i=0
for p in $PARTS; do
  i=$((i+1))
  URL="$RAW/passwall.part.$p"
  OUTF="$DL/passwall.part.$p"
  log "[$i/8] Fetching part .$p ..."
  if ! wget -q -O "$OUTF" "$URL"; then
    log "ERROR: failed to download part .$p from $URL"
    exit 2
  fi
done

# Optional helper ipks
mkdir -p "$OUT/ipk"
for f in bash_ libnettle8_ libgmp10_; do
  URL="$RAW/ipk/$(basename $(wget -q -O- $RAW/ipk/ 2>/dev/null | sed -n 's/.*href="\(.*'"$f"'.*ipk\)".*/\1/p' | head -n1))"
  case "$URL" in http*ipk)
    log "Fetching helper ipk: $(basename "$URL")"
    wget -q -O "$OUT/ipk/$(basename "$URL")" "$URL" || true
  esac
done

log "Joining parts -> tar.gz ..."
cat "$DL"/passwall.part.* > "$OUT/passwall_offline_bundle.tar.gz"

if [ -s "$DL/SHA256SUMS.txt" ]; then
  log "Verifying SHA256 (non-fatal) ..."
  sha256sum -c "$DL/SHA256SUMS.txt" 2>/dev/null || log "WARN: checksum mismatch (continuing)."
fi

log "Extracting ..."
tar -xzf "$OUT/passwall_offline_bundle.tar.gz" -C "$OUT"

REPOROOT="$OUT/passwall_offline_bundle"
[ -d "$REPOROOT" ] || { log "ERROR: extracted folder not found."; exit 3; }

# install helper ipk if present (non-fatal)
if ls "$OUT/ipk/"*.ipk >/dev/null 2>&1; then
  log "Installing helper ipk(s) if needed ..."
  for ipk in "$OUT"/ipk/*.ipk; do
    opkg install "$ipk" 2>>"$LOG" || log "WARN: opkg skipped $(basename "$ipk")"
  done
fi

log "Installing Passwall from offline repo: $REPOROOT/$REPO_SUB/"
opkg install "$REPOROOT/$REPO_SUB"/*.ipk 2>>"$LOG" || true

# enable + start
log "Enabling & starting Passwall ..."
/etc/init.d/passwall enable 2>/dev/null || true
/etc/init.d/passwall start  2>/dev/null || true

log "Done. Open LuCI → Services → Passwall."
log "Report: /tmp/passwall_offline_install_report.txt"

# Optional: write a short report
{
  echo "Version: $VER"
  echo "Repo: $REPOROOT/$REPO_SUB"
  opkg list-installed | grep -E 'passwall|xray|sing-box|shadowsocks|chinadns|hysteria' || true
} > /tmp/passwall_offline_install_report.txt

# leave workspace for now (debug). Uncomment to auto-clean:
# rm -rf "$BASE"
exit 0
