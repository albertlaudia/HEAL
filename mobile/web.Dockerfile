# HEAL Flutter Web — production Dockerfile
#
# Build context: /mobile (set in Dokploy)
# Build path:   /mobile (set in Dokploy)
# Output:       static SPA bundle served by Nginx

# ── Stage 1: Build the Flutter web bundle ────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS builder

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
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /build/build/web /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]