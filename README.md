# excalidraw-railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/excalidraw-or-just-updated-whiteboard-wh?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

**Deploy on Railway:** [Excalidraw template](https://railway.com/deploy/excalidraw-or-just-updated-whiteboard-wh?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

Wrapper image for deploying [Excalidraw](https://github.com/excalidraw/excalidraw) on
[Railway](https://railway.com) with a **private collaboration server**.

`ghcr.io/bon5co/excalidraw-railway:2026.08.18`

## Why a wrapper

Excalidraw is a Vite app: every `VITE_APP_*` value is substituted into the JavaScript
bundle at build time. The official `excalidraw/excalidraw` image therefore ships with
`https://oss-collab.excalidraw.com` — Excalidraw's own public relay — baked into
`assets/index-*.js`, and setting `VITE_APP_WS_SERVER_URL` as a runtime environment
variable changes nothing. A deploy that pairs the official image with that variable and
its own `excalidraw-room` service looks correct and still relays every live session
through excalidraw.com, while billing for a collaboration server that receives no
traffic.

This image:

- rewrites the baked relay URL at container start from `EXCALIDRAW_ROOM_URL`;
- **refuses to start** if any reference to the public relay survives the rewrite, so a
  future upstream change fails the deploy instead of silently sending sessions offsite;
- makes nginx listen on the `PORT` Railway injects (the stock config is a fixed
  `listen 80;`, which Railway's healthcheck does not dial);
- is pinned to a digest of the upstream image rather than tracking `:latest`.

## Environment

| Variable | Meaning |
| --- | --- |
| `EXCALIDRAW_ROOM_URL` | Public URL of the `excalidraw-room` server, e.g. `https://room.up.railway.app`. A bare hostname is accepted and `https://` is assumed. Must be reachable from the browser: a Railway *private* domain will not work. |
| `PORT` | Port nginx listens on. Defaults to 80. |

Pair it with the official `excalidraw/excalidraw-room` image (which reads `PORT` and
`CORS_ORIGIN` itself) on its own public domain.

## Notes

Live collaboration is end-to-end encrypted in the browser and, with this image, relayed
by your own room server. Excalidraw's own scene-persistence and "export to shareable
link" features still address `json.excalidraw.com` and Excalidraw's Firebase project;
those are baked into the upstream build as well and are not changed here.
