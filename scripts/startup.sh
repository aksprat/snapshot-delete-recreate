#!/bin/bash
set -e

source ../.env

echo "🔍 Finding latest snapshot..."
SNAPSHOT_LINE=$(doctl compute snapshot list --resource droplet \
  --format ID,Name,Created \
  --no-header | grep $DROPLET_NAME | sort -k3 -r | head -n1)

SNAPSHOT_ID=$(echo $SNAPSHOT_LINE | awk '{print $1}')
SNAPSHOT_NAME=$(echo $SNAPSHOT_LINE | awk '{print $2}')

if [ -z "$SNAPSHOT_ID" ]; then
  echo "❌ No snapshot found!"
  exit 1
fi

echo "🚀 Creating Droplet from snapshot..."
CREATE_CMD="doctl compute droplet create $DROPLET_NAME \
  --region $REGION \
  --size $SIZE \
  --image $SNAPSHOT_ID \
  --format ID \
  --no-header"

if [ ! -z "$SSH_KEY_FINGERPRINT" ]; then
  CREATE_CMD="$CREATE_CMD --ssh-keys $SSH_KEY_FINGERPRINT"
fi

DROPLET_ID=$(eval $CREATE_CMD)

echo "⏳ Waiting for Droplet to become active..."
while true; do
  STATUS=$(doctl compute droplet get $DROPLET_ID --format Status --no-header)
  if [ "$STATUS" == "active" ]; then
    break
  fi
  sleep 5
done

echo "🌐 Assigning Reserved IP..."
if [ ! -z "$RESERVED_IP" ]; then
  doctl compute reserved-ip-action assign $RESERVED_IP --droplet-id $DROPLET_ID
fi

# 🔥 Optional: Delete snapshot after use
if [ "$DELETE_SNAPSHOT" == "true" ]; then
  echo "🧹 Deleting snapshot: $SNAPSHOT_NAME"
  doctl compute snapshot delete $SNAPSHOT_ID -f
fi

echo "✅ Startup complete. Droplet ID: $DROPLET_ID"
