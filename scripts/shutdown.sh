#!/bin/bash
set -e

source ../.env

echo "🔍 Finding Droplet ID..."
DROPLET_ID=$(doctl compute droplet list --format ID,Name --no-header | grep $DROPLET_NAME | awk '{print $1}')

if [ -z "$DROPLET_ID" ]; then
  echo "❌ Droplet not found!"
  exit 1
fi

SNAPSHOT_NAME="${DROPLET_NAME}-snapshot-$(date +%Y%m%d%H%M)"

echo "📸 Creating snapshot: $SNAPSHOT_NAME"
ACTION_ID=$(doctl compute droplet-action snapshot $DROPLET_ID --snapshot-name $SNAPSHOT_NAME --format ID --no-header)

echo "⏳ Waiting for snapshot to complete..."
while true; do
  STATUS=$(doctl compute action get $ACTION_ID --format Status --no-header)
  if [ "$STATUS" == "completed" ]; then
    break
  fi
  sleep 5
done

echo "🌐 Detaching Reserved IP..."
if [ ! -z "$RESERVED_IP" ]; then
  doctl compute reserved-ip-action unassign $RESERVED_IP || true
fi

echo "🗑️ Destroying Droplet..."
doctl compute droplet delete $DROPLET_ID -f

echo "✅ Shutdown complete. Snapshot saved: $SNAPSHOT_NAME"
