#!/bin/bash
# HEAL — auto-sync Traefik config when heal-app container IP changes
set -e
SERVICE_NAME="heal-app-apsqyt"
CONF="/etc/dokploy/traefik/dynamic/heal-app-apsqyt.yml"
TEMPLATE="/etc/dokploy/traefik/dynamic/heal-app-apsqyt.yml.tmpl"
DOMAIN="heal.positiveness.club"

NEW_IP=$(docker inspect $(docker ps --filter name=$SERVICE_NAME --filter status=running --format '{{.Names}}' | head -1) --format '{{(index .NetworkSettings.Networks "dokploy-network").IPAddress}}' 2>/dev/null)
[ -z "$NEW_IP" ] && exit 0

CUR_IP=$(grep -oE 'http://[0-9.]+:3000' "$CONF" 2>/dev/null | head -1 | cut -d/ -f3 | cut -d: -f1)

if [ "$NEW_IP" != "$CUR_IP" ] && [ -n "$NEW_IP" ]; then
    echo "[$(date)] IP change: $CUR_IP -> $NEW_IP"
    sed "s|__IP__|$NEW_IP|g" "$TEMPLATE" > "$CONF"
    docker kill -s HUP traefik 2>/dev/null
fi
