#!/usr/bin/env bash
# Fetch recent successful Hydra builds and find the most recent with cache available
# Usage: fetch-hydra-builds.sh <jobset> <current-commit>
# Example: fetch-hydra-builds.sh "nixpkgs/unstable/unstable" "0f7663154ff2fec150f9dbf5f81ec2785dc1e0db"

set -euo pipefail

JOBSET="$1"
CURRENT_COMMIT="$2"
MAX_BUILDS="${3:-5}"

# Parse jobset into components
IFS='/' read -r PROJECT JOBSET_NAME JOB <<< "$JOBSET"

echo "Querying Hydra jobset: $JOBSET" >&2

# Get the latest successful build for this job
echo "Fetching latest successful build..." >&2
LATEST=$(curl -sL -H "Accept: application/json" \
  "https://hydra.nixos.org/job/$PROJECT/$JOBSET_NAME/$JOB/latest" 2>/dev/null || echo "{}")

if [[ "$LATEST" == "{}" ]]; then
  echo "Error: Could not fetch latest build from Hydra" >&2
  exit 1
fi

BUILD_ID=$(echo "$LATEST" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('id', ''))" 2>/dev/null)
FIRST_EVAL_ID=$(echo "$LATEST" | python3 -c "import sys, json; data=json.load(sys.stdin); evals=data.get('jobsetevals', []); print(evals[0] if evals else '')" 2>/dev/null)

if [[ -z "$BUILD_ID" ]] || [[ -z "$FIRST_EVAL_ID" ]]; then
  echo "Error: Could not parse build/eval ID from Hydra response" >&2
  exit 1
fi

echo "Starting from Build #$BUILD_ID, Eval #$FIRST_EVAL_ID" >&2

# Now iterate through recent evaluations to find one with cache
FOUND=0
EVAL_ID="$FIRST_EVAL_ID"
CHECKED_COUNT=0
CURRENT_BUILD_ID="$BUILD_ID"

for i in $(seq 0 $((MAX_BUILDS - 1))); do
  if [[ $CHECKED_COUNT -ge $MAX_BUILDS ]]; then
    break
  fi
  
  echo "Checking Eval #$EVAL_ID (Build #$CURRENT_BUILD_ID)..." >&2
  
  # Get evaluation details
  EVAL_DATA=$(curl -sL -H "Accept: application/json" \
    "https://hydra.nixos.org/eval/$EVAL_ID" 2>/dev/null || echo "{}")
  
  if [[ "$EVAL_DATA" == "{}" ]]; then
    echo "  Warning: Could not fetch eval data, trying next..." >&2
    ((EVAL_ID--))
    ((CHECKED_COUNT++))
    CURRENT_BUILD_ID=$((CURRENT_BUILD_ID - 1))
    continue
  fi
  
  # Extract nixpkgs revision
  REVISION=$(echo "$EVAL_DATA" | python3 -c "
import sys, json
data = json.load(sys.stdin)
inputs = data.get('jobsetevalinputs', {})
nixpkgs = inputs.get('nixpkgs', {})
print(nixpkgs.get('revision', ''))
" 2>/dev/null)
  
  if [[ -z "$REVISION" ]]; then
    echo "  Warning: Could not extract revision from eval, trying next..." >&2
    ((EVAL_ID--))
    ((CHECKED_COUNT++))
    CURRENT_BUILD_ID=$((CURRENT_BUILD_ID - 1))
    continue
  fi
  
  # Get constituents of the CURRENT_BUILD_ID to check for cachix
  CONSTITUENTS=$(curl -sL -H "Accept: application/json" \
    "https://hydra.nixos.org/build/$CURRENT_BUILD_ID/constituents" 2>/dev/null || echo "[]")
  
  # Check if any cachix builds succeeded (buildstatus = 0)
  CACHIX_AVAILABLE=$(echo "$CONSTITUENTS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cachix_builds = [b for b in data if 'cachix' in b.get('job', '').lower()]
successful_cachix = [b for b in cachix_builds if b.get('buildstatus') == 0]
print('yes' if successful_cachix else 'no')
" 2>/dev/null)
  
  echo "  Revision: $REVISION, Cachix: $CACHIX_AVAILABLE" >&2
  
  if [[ "$CACHIX_AVAILABLE" == "yes" ]]; then
    echo "Found successful build with cache at Eval #$EVAL_ID" >&2
    
    # Get commit metadata from GitHub
    COMMIT_INFO=$(curl -sL "https://api.github.com/repos/nixos/nixpkgs/commits/$REVISION" 2>/dev/null || echo "{}")
    
    COMMIT_DATE=$(echo "$COMMIT_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'commit' in data:
    print(data['commit'].get('committer', {}).get('date', 'unknown'))
else:
    print('unknown')
" 2>/dev/null)
    
    COMMIT_MESSAGE=$(echo "$COMMIT_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'commit' in data:
    msg = data['commit'].get('message', '')
    print(msg.split('\n')[0] if msg else 'unknown')
else:
    print('unknown')
" 2>/dev/null)
    
    # Get cachix platforms that succeeded
    CACHIX_PLATFORMS=$(echo "$CONSTITUENTS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cachix_builds = [b for b in data if 'cachix' in b.get('job', '').lower()]
successful_cachix = [b for b in cachix_builds if b.get('buildstatus') == 0]
platforms = [b.get('job', '').replace('cachix.', '') for b in successful_cachix]
print(', '.join(sorted(platforms)))
" 2>/dev/null)
    
    # Output as JSON
    python3 << EOF
import json
result = {
    'revision': '$REVISION',
    'build_id': '$CURRENT_BUILD_ID',
    'eval_id': '$EVAL_ID',
    'commit_date': '$COMMIT_DATE',
    'commit_message': '$COMMIT_MESSAGE',
    'cachix_platforms': '$CACHIX_PLATFORMS'
}
print(json.dumps(result))
EOF
    
    FOUND=1
    break
  fi
  
  ((EVAL_ID--))
  ((CHECKED_COUNT++))
  CURRENT_BUILD_ID=$((CURRENT_BUILD_ID - 1))
done

if [[ $FOUND -eq 0 ]]; then
  echo "Error: None of the last $MAX_BUILDS successful builds have cachix available" >&2
  exit 1
fi
