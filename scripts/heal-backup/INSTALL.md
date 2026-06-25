# HEAL PB auto-backup — VPS install steps

## One-time setup (run once on the Dokploy VPS)

```bash
# 1. Create the backup directory
sudo mkdir -p /opt/heal-backup
sudo chown root:root /opt/heal-backup

# 2. Copy the backup + restore scripts from this repo
# (we'll add them to the repo in a moment)
sudo cp scripts/heal-backup/backup.sh /opt/heal-backup/backup.sh
sudo cp scripts/heal-backup/restore.sh /opt/heal-backup/restore.sh
sudo chmod 700 /opt/heal-backup/*.sh

# 3. Create the env file with your B2 credentials
sudo tee /etc/heal-backup.env > /dev/null <<'EOF'
# HEAL PB backup — DO NOT COMMIT
PB_DATA_DIR=/var/lib/dokploy/volumes/heal-pb/pb_data
PB_URL=http://localhost:8090
PB_IDENTITY=minimax@scaleupcrm.com
PB_PASSWORD=YOUR_NEW_PB_PASSWORD_HERE

# Backblaze B2 (create app key with read+write to heal-backups bucket only)
B2_KEY_ID=005xxxxxxxxxxxxx
B2_APP_KEY=K005xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
B2_BUCKET=heal-backups
B2_ENDPOINT=https://s3.us-west-004.backblazeb2.com
B2_PREFIX=heal/

# Retention + alerts
RETENTION_DAYS=30
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
EOF
sudo chmod 600 /etc/heal-backup.env

# 4. Install the cron job (runs at 03:00 UTC daily)
sudo tee /etc/cron.d/heal-backup > /dev/null <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# m h dom mon dow user  command
0 3 * * *   root   /opt/heal-backup/backup.sh
EOF
sudo chmod 644 /etc/cron.d/heal-backup

# 5. Verify cron is running
sudo systemctl status cron
ls -la /etc/cron.d/heal-backup

# 6. Test the backup runs cleanly (DO THIS NOW)
sudo /opt/heal-backup/backup.sh
# Watch the log:
tail -f /var/log/heal-backup.log

# 7. Verify the backup landed in B2
s3cmd ls s3://heal-backups/heal/ --config=/root/.s3cfg-heal
```

## Day-2: Test a restore

Run this on a SEPARATE machine (or in a fresh Docker container) to prove
a backup is actually restorable — a backup you can't restore is no backup.

```bash
# On a fresh box:
git clone https://github.com/albertlaudia/HEAL.git
cd HEAL
# Copy the same scripts + env (without the prod password):
sudo cp scripts/heal-backup/restore.sh /opt/heal-backup/restore.sh
sudo chmod +x /opt/heal-backup/restore.sh
# Run with the latest backup:
sudo /opt/heal-backup/restore.sh latest
# Inspect: do the records match what the live PB has?
ls -la /tmp/heal-restore/
```

## Monitoring checklist

- [ ] `/var/log/heal-backup.log` has a fresh entry every day at 03:00 UTC
- [ ] Slack webhook fires `✅ HEAL PB backup OK` daily
- [ ] B2 bucket has 7+ backups (one per day, retention working)
- [ ] Monthly: pick a random backup, run `restore.sh` on a clean machine,
      diff record counts against live PB to confirm zero drift

## Recovery scenario (when you actually need it)

```bash
# 1. SSH to Dokploy VPS
# 2. Find the PB container
docker ps | grep pocketbase
# 3. Stop the container
docker stop <pb-container-id>
# 4. Back up the current (broken) data first
mv /var/lib/dokploy/volumes/heal-pb/pb_data /var/lib/dokploy/volumes/heal-pb/pb_data.broken
# 5. Restore from B2
mkdir -p /var/lib/dokploy/volumes/heal-pb/pb_data
cd /tmp
s3cmd get s3://heal-backups/heal/heal-pb-2026-06-25T03-00.tar.gz --config=/root/.s3cfg-heal
tar -xzf heal-pb-2026-06-25T03-00.tar.gz -C /var/lib/dokploy/volumes/heal-pb/pb_data/ --strip-components=1
# 6. Restart PB
docker start <pb-container-id>
# 7. Verify
curl -s https://pocketbase.scaleupcrm.com/api/health
```