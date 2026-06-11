#!/bin/bash
# check-b2-ready.sh — verifies B2 credentials + bucket access
# Run this AFTER providing the new bucket-scoped key to confirm we're ready to upload.

set -e

echo "🌿 HEAL — B2 readiness check"
echo ""

# 1. Check env vars
if [ -z "$B2_KEY_ID" ] || [ -z "$B2_APPLICATION_KEY" ]; then
  echo "❌ Missing B2_KEY_ID or B2_APPLICATION_KEY"
  exit 1
fi

if [ -z "$B2_BUCKET_ID" ]; then
  echo "⚠️  B2_BUCKET_ID not set — find in B2 web UI"
  echo "   Buckets → click bucket name → 'Bucket ID' column"
  exit 1
fi

# 2. Authorize
echo "1. Testing authorization..."
AUTH_RESPONSE=$(curl -s -u "${B2_KEY_ID}:${B2_APPLICATION_KEY}" "https://api.backblazeb2.com/b2api/v2/b2_authorize_account")
if echo "$AUTH_RESPONSE" | grep -q "authorizationToken"; then
  echo "   ✓ Authorized"
else
  echo "   ❌ Authorization failed:"
  echo "$AUTH_RESPONSE" | head -3
  exit 1
fi

# 3. List buckets
echo "2. Testing bucket access..."
ACCOUNT_ID=$(echo "$AUTH_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin)['accountId'])")
API_URL=$(echo "$AUTH_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin)['apiUrl'])")
BUCKETS=$(curl -s -u "${B2_KEY_ID}:${B2_APPLICATION_KEY}" -X POST "${API_URL}/b2api/v2/b2_list_buckets" -H "Content-Type: application/json" -d "{\"accountId\":\"${ACCOUNT_ID}\"}" 2>&1)
if echo "$BUCKETS" | grep -q "bad_auth_token"; then
  echo "   ❌ Bucket scope missing — key is account-only"
  echo "      Create a bucket-scoped key in B2 web UI:"
  echo "        App Keys → Add a New Application Key"
  echo "        Type: Read and Write"
  echo "        Bucket(s): your bucket (e.g. heal-media)"
  echo "        Scope: scope to that bucket only"
  echo "        Then paste the new keyId + applicationKey back here"
  exit 1
fi
echo "   ✓ Bucket access OK"
echo "$BUCKETS" | python3 -c "
import json, sys
try:
  d = json.load(sys.stdin)
  for b in d.get('buckets', []):
    print('      bucket:', b['bucketName'], '| id:', b['bucketId'])
except Exception as e:
  print('      could not parse:', e)
"

# 4. Test upload to bucket
echo "3. Testing upload URL..."
GET_URL=$(curl -s -u "${B2_KEY_ID}:${B2_APPLICATION_KEY}" -X POST "${API_URL}/b2api/v2/b2_get_upload_url" -H "Content-Type: application/json" -d "{\"bucketId\":\"${B2_BUCKET_ID}\"}" 2>&1)
if echo "$GET_URL" | grep -q "uploadUrl"; then
  echo "   ✓ Can request upload URL"
else
  echo "   ❌ Cannot get upload URL: $GET_URL"
  exit 1
fi

echo ""
echo "✅ B2 is fully ready. Run: pnpm media:upload"
