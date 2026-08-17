# Excalidraw frontend, packaged for Railway.
#
# The official image bakes every VITE_APP_* value into the JavaScript bundle at build
# time, so setting VITE_APP_WS_SERVER_URL as a runtime environment variable has no
# effect: the app still opens its collaboration socket against Excalidraw's public
# relay. This wrapper rewrites the baked value at container start, verifies the rewrite
# actually happened, and makes nginx listen on the port Railway injects.
FROM excalidraw/excalidraw@sha256:f7ee194addd607bf831d2af0f0a34463dd4225e426cf35199ef0b12a803398e9

# Keep a pristine copy of the built site outside the served directory so every boot
# patches the original rather than a previously patched file.
RUN cp -a /usr/share/nginx/html /opt/excalidraw-html

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
