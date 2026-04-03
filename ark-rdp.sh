#!/usr/bin/env bash
# ark-rdp.sh - Wrapper to fetch and auto-open an RDP file via ark-cli
#
# Usage: ark-rdp.sh -h <target_host>
#
# Will interactively prompt for connection type (ZSP, Standing, or Privilege
# Elevation) and, if Standing or Privilege Elevation, for username and domain.

set -euo pipefail

# -- Configuration (edit before use) ------------------------------------------
PROFILE_NAME=""
DEFAULT_USER=""
DEFAULT_DOMAIN=""
OUTPUT_DIR=""

# -- Argument parsing ----------------------------------------------------------
usage() {
  echo "Usage: $(basename "$0") -h <target_host>"
  echo ""
  echo "  -h  Target host (required)"
  exit 1
}

TARGET_HOST=""

while getopts ":h:" opt; do
  case $opt in
    h) TARGET_HOST="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$TARGET_HOST" ]]; then
  echo "Error: target host (-h) is required."
  usage
fi

# -- Prompt for profile name ---------------------------------------------------
echo ""
read -rp "Profile name [$PROFILE_NAME]: " INPUT_PROFILE
PROFILE_NAME="${INPUT_PROFILE:-$PROFILE_NAME}"

# -- Prompt for connection type ------------------------------------------------
echo ""
echo "Connection type:"
echo "  1) ZSP                 (no credentials required)"
echo "  2) Standing            (username + domain required)"
echo "  3) Privilege Elevation (username + domain required)"
echo ""
read -rp "Select [1/2/3]: " CONN_TYPE

case "$CONN_TYPE" in
  1) CONN_MODE="zsp" ;;
  2) CONN_MODE="standing" ;;
  3) CONN_MODE="elevation" ;;
  *)
    echo "Error: invalid selection."
    exit 1
    ;;
esac

# -- Prompt for credentials if Standing or Privilege Elevation -----------------
if [[ "$CONN_MODE" == "standing" || "$CONN_MODE" == "elevation" ]]; then
  read -rp "Username [$DEFAULT_USER]: " RDP_USER
  RDP_USER="${RDP_USER:-$DEFAULT_USER}"

  read -rp "Domain [$DEFAULT_DOMAIN]: " RDP_DOMAIN
  RDP_DOMAIN="${RDP_DOMAIN:-$DEFAULT_DOMAIN}"
fi

# -- Validate configuration ----------------------------------------------------
if [[ -z "$OUTPUT_DIR" ]]; then
  echo "Error: OUTPUT_DIR is not set. Edit the configuration and set it before use."
  exit 1
fi

# -- Ensure output directory exists --------------------------------------------
mkdir -p "$OUTPUT_DIR"

# -- Run ark -------------------------------------------------------------------
echo ""
echo "Fetching RDP file for $TARGET_HOST..."

case "$CONN_MODE" in
  zsp)
    ark exec -ra -pn "$PROFILE_NAME" sia sso short-lived-rdp-file \
      -ta "$TARGET_HOST" \
      -f "$OUTPUT_DIR"
    ;;
  standing)
    ark exec -ra -pn "$PROFILE_NAME" sia sso short-lived-rdp-file \
      -ta "$TARGET_HOST" \
      -tu "$RDP_USER" \
      -td "$RDP_DOMAIN" \
      -f "$OUTPUT_DIR"
    ;;
  elevation)
    ark exec -ra -pn "$PROFILE_NAME" sia sso short-lived-rdp-file \
      -ta "$TARGET_HOST" \
      -tu "$RDP_USER" \
      -td "$RDP_DOMAIN" \
      -ep \
      -f "$OUTPUT_DIR"
    ;;
esac

# -- Open the most recently created file in the output directory ---------------
LATEST="$(ls -t "$OUTPUT_DIR" | head -n1)"

if [[ -z "$LATEST" ]]; then
  echo "Error: No files found in $OUTPUT_DIR after ark exec."
  exit 1
fi

echo "Opening $OUTPUT_DIR/$LATEST"
open "$OUTPUT_DIR/$LATEST"