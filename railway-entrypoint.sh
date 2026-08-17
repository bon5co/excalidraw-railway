#!/bin/sh
# Boot-time configuration for Excalidraw on Railway.
#
#   EXCALIDRAW_ROOM_URL  public URL of the excalidraw-room collaboration server
#   PORT                 port nginx should listen on (Railway injects this)
set -eu

UPSTREAM_RELAY="https://oss-collab.excalidraw.com"
HTML_DIR="/usr/share/nginx/html"

# Always start from the unpatched build.
rm -rf "$HTML_DIR"
cp -a /opt/excalidraw-html "$HTML_DIR"

room_url="${EXCALIDRAW_ROOM_URL:-}"

if [ -n "$room_url" ]; then
  # Accept a bare hostname (Railway reference variables resolve to one) and normalise.
  case "$room_url" in
    http://*|https://*) : ;;
    *) room_url="https://${room_url}" ;;
  esac
  room_url="${room_url%/}"

  case "$room_url" in
    http://*)
      echo "[entrypoint] WARNING: EXCALIDRAW_ROOM_URL is http://; a page served over" >&2
      echo "[entrypoint]          https cannot open a socket to it (mixed content)." >&2
      ;;
  esac

  echo "[entrypoint] pointing collaboration at ${room_url}"
  find "$HTML_DIR" -name '*.js' -type f -exec \
    sed -i "s|${UPSTREAM_RELAY}|${room_url}|g" {} +

  remaining=$(grep -rl "oss-collab.excalidraw.com" "$HTML_DIR" 2>/dev/null | wc -l)
  if [ "$remaining" -ne 0 ]; then
    echo "[entrypoint] FATAL: the bundle still points at Excalidraw's public relay after" >&2
    echo "[entrypoint]        patching. Refusing to start: collaboration would silently" >&2
    echo "[entrypoint]        run through excalidraw.com instead of your own server." >&2
    exit 1
  fi
  echo "[entrypoint] collaboration relay patched, 0 references to the public relay remain"
else
  echo "[entrypoint] WARNING: EXCALIDRAW_ROOM_URL is unset — live collaboration will use" >&2
  echo "[entrypoint]          Excalidraw's public relay at ${UPSTREAM_RELAY}." >&2
fi

# The image's nginx config is a fixed `listen 80;`. Railway injects PORT and its
# healthcheck dials that port, so honour it.
port="${PORT:-80}"
sed -i "s/listen  *80;/listen       ${port};/" /etc/nginx/conf.d/default.conf
echo "[entrypoint] nginx listening on ${port}"

exec /docker-entrypoint.sh "$@"
