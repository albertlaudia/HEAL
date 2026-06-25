#!/bin/bash
# HEAL — find where PB data actually lives on the Dokploy VPS
# Run this on the Dokploy host (not the HEAL container, not your laptop)
#
# This produces the path that goes into /etc/heal-backup.env as PB_DATA_DIR

echo "=== All dokploy volume mounts ==="
mount | grep dokploy 2>/dev/null
echo ""
echo "=== Looking for pb_data directories ==="
find / -name "pb_data" -type d 2>/dev/null | head -10
echo ""
echo "=== Looking for our specific collections ==="
find / -name "HEAL_meditations" -type d 2>/dev/null | head -5
echo ""
echo "=== PB container status ==="
docker ps -a 2>/dev/null | grep -i pocket
echo ""
echo "=== Disk usage of candidate paths ==="
for p in $(find / -name "pb_data" -type d 2>/dev/null | head -3); do
  echo ""
  echo "  $p:"
  du -sh "$p" 2>/dev/null
  ls -la "$p" 2>/dev/null | head -10
done