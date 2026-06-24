#!/bin/bash
# Generate illustrations in batches of 10
# Usage: bash scripts/batch-illustrate.sh <start_index>

set -e

START=${1:-0}
BATCH_SIZE=10
TOTAL=$(node -e "console.log(require('/tmp/meditation-prompts.json').length)")
echo "Total prompts: $TOTAL, starting at $START, batch size $BATCH_SIZE"

END=$((START + BATCH_SIZE))
if [ $END -gt $TOTAL ]; then END=$TOTAL; fi

PROMPTS_JSON=$(node -e "
const ps = require('/tmp/meditation-prompts.json').slice($START, $END);
const requests = ps.map(p => ({
  prompt: p.prompt,
  output_file_path: '/workspace/HEAL/public/images/meditations/illustration-' + p.slug + '.png',
  aspect_ratio: '2:1',
  resolution: '1K'
}));
console.log(JSON.stringify(requests));
")

# Use a temp file to pass JSON to the agent
echo "$PROMPTS_JSON" > /tmp/batch-requests.json
echo "Batch $START-$END ready in /tmp/batch-requests.json"
echo "Run the image_synthesize call with this JSON"
