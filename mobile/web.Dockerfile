# HEAL Flutter Web — production Dockerfile
#
# Build context: /mobile (set in Dokploy)
# Build path:   /mobile (set in Dokploy)
# Output:       static SPA bundle served by Nginx

# ── Stage 1: Build the Flutter web bundle ────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.32.0 AS builder

WORKDIR /build

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

ARG PB_URL=https://pocketbase.scaleupcrm.com
ARG CDN_URL=https://resources.positiveness.club/heal
ARG SITE_URL=https://healf.positiveness.club
ARG FIREBASE_API_KEY=""
ARG FIREBASE_PROJECT_ID=""
ARG FIREBASE_APP_ID=""
ARG FIREBASE_MESSAGING_SENDER_ID=""

RUN flutter build web --release \
  --no-tree-shake-icons \
  --source-maps \
  --dart-define=PB_URL=${PB_URL} \
  --dart-define=CDN_URL=${CDN_URL} \
  --dart-define=SITE_URL=${SITE_URL} \
  --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
  --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
  --dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID} \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}

# ── Stage 2: Serve via Nginx ────────────────────────────────────
FROM nginx:1.27-alpine AS runner

COPY <<NGINX_CONF /etc/nginx/conf.d/default.conf
server {
  listen 80;
  server_name _;

  root /usr/share/nginx/html;
  index index.html;

  # Flutter SPA — every unknown path falls back to index.html
  location / {
    try_files \$uri \$uri/ /index.html;
  }

  # Long cache for hashed assets
  location ~* \.(js|css|wasm|woff2?|ttf|otf|png|jpg|jpeg|gif|svg|ico|map)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
  }

  # Never cache index.html — we want deploys to take effect immediately
  location = /index.html {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    expires 0;
  }

  # Short cache on manifest.json + future service worker
  location ~* (manifest\.json|sw\.js|workbox-.*\.js)$ {
    add_header Cache-Control "no-cache, must-revalidate";
    expires 1h;
  }

  # Gzip everything text-like
  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/json
    application/javascript
    application/xml+rss
    application/atom+xml
    image/svg+xml;

  # Security headers
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  add_header Permissions-Policy "microphone=(self), camera=(), geolocation=()" always;

  types {
    application/wasm wasm;
    application/javascript js;
    text/javascript js;
  }
  default_type application/octet-stream;

  server_tokens off;
}
NGINX_CONF

COPY --from=builder /build/build/web /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]