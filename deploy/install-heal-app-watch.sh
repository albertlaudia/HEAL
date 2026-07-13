#!/bin/bash
# HEAL — auto-sync Traefik config when heal-app container IP changes

cat > /usr/local/bin/heal-app-traefik-watch.sh << 'WATCH'
#!/bin/bash
set -e
SERVICE_NAME="heal-app-apsqyt"
CONF="/etc/dokploy/traefik/dynamic/heal-app-apsqyt.yml"
DOMAIN="heal.positiveness.club"

# Get current container IP
NEW_IP=$(docker inspect $(docker ps --filter name=$SERVICE_NAME --filter status=running --format '{{.Names}}' | head -1) --format '{{(index .NetworkSettings.Networks "dokploy-network").IPAddress}}' 2>/dev/null)
if [ -z "$NEW_IP" ]; then exit 0; fi

# Get current IP in config
CUR_IP=$(grep -oE 'http://[0-9.]+:3000' "$CONF" 2>/dev/null | head -1 | cut -d/ -f3 | cut -d: -f1)

if [ "$NEW_IP" != "$CUR_IP" ] && [ -n "$NEW_IP" ]; then
    echo "[$(date)] IP change: $CUR_IP -> $NEW_IP"
    cat > "$CONF" <<YML
http:
  routers:
    heal-app-apsqyt-router:
      rule: Host("$DOMAIN")
      service: heal-app-apsqyt-service
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
  services:
    heal-app-apsqyt-service:
      loadBalancer:
        servers:
          - url: http://$NEW_IP:3000
YML
    docker kill -s HUP traefik 2>/dev/null
fi
WATCH
chmod +x /usr/local/bin/heal-app-traefik-watch.sh

# Cron every 5 min
cat > /etc/cron.d/heal-app-watch << 'CRON'
*/5 * * * * root /usr/local/bin/heal-app-traefik-watch.sh >> /var/log/heal-app-traefik-watch.log 2>&1
CRON
echo "Installed"
