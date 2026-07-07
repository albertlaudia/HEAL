#!/bin/bash
# HEAL Flutter Web — Traefik watcher.
# Polls the heal-flutter-web container IP every 10s and rewrites the
# Traefik dynamic config so https://healf.positiveness.club routes to it.
#
# The container may attach to either or both of:
#   - dokploy-bridge  (172.20.0.0/16) — preferred when present
#   - dokploy-network (10.0.1.0/24)   — swarm overlay, always present
# We try bridge first, fall back to network, fall back to single IP.
#
# IMPORTANT: do NOT use `{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}`.
# Docker's range iterator returns concatenated IPs without separator when the
# container is on multiple networks → invalid URL like "http://172.20.0.4410.0.1.207:80".

LAST_IP=
TMPL=/etc/dokploy/traefik/dynamic/heal-flutter-web.yml.tmpl
OUT=/etc/dokploy/traefik/dynamic/heal-flutter-web.yml

while true; do
  CONTAINER=$(docker ps -a --filter name=heal-flutter-web --filter status=running --format '{{.Names}}'2>/dev/null | head -1)
  if [ -n "$CONTAINER" ]; then
    IP=$(docker inspect "$CONTAINER" --format '{{(index .NetworkSettings.Networks "dokploy-bridge").IPAddress}}'2>/dev/null)
    if [ -z "$IP" ]; then
      IP=$(docker inspect "$CONTAINER" --format '{{(index .NetworkSettings.Networks "dokploy-network").IPAddress}}'2>/dev/null)
    fi
    if [ -z "$IP" ]; then
      IP=$(docker inspect "$CONTAINER" --format '{{.NetworkSettings.IPAddress}}'2>/dev/null)
    fi
    if [ -n "$IP" ] && [ "$IP" != "$LAST_IP" ]; then
      # Always re-render from template (never edit in place) so the URL line
      # is replaced cleanly with no carry-over from previous runs.
      sed "s|__IP__|$IP|g" "$TMPL" > "$OUT"
      docker kill -s HUP traefik 2>/dev/null
      echo "[$(date -Is)] Updated traefik config to IP $IP"
      LAST_IP=$IP
    fi
  fi
  sleep 10
done
