#!/usr/bin/env bash
set -euo pipefail

DB_PATH="$HOME/Library/Containers/com.tomito.tomito/Data/Library/Application Support/Tomito/Tomito.sqlite"
CACHE_DIR="$HOME/.cache/sketchybar"
CACHE_FILE="$CACHE_DIR/tomito_pause_cache"
CORE_DATA_EPOCH_OFFSET=978307200

idle() {
  rm -f "$CACHE_FILE"
  echo "idle|"
  exit 0
}

get_pause_state() {
  local result
  result=$(osascript -e 'tell application "System Events" to tell process "Tomito" to get name of every menu item of menu "Timer" of menu bar item "Timer" of menu bar 1' 2>/dev/null) || echo "unknown"
  
  if [[ "$result" == *"Resume"* ]]; then
    echo "paused"
  elif [[ "$result" == *"Pause"* ]]; then
    echo "running"
  else
    echo "unknown"
  fi
}

[[ -f "$DB_PATH" ]] || idle

RESULT=$(sqlite3 "$DB_PATH" "
  SELECT Z_PK, ZTYPE, ZDURATION, ZPROGRESSED, ZSTARTEDAT
  FROM ZACTIVITY 
  WHERE ZFINISHEDAT IS NULL 
  ORDER BY ZSTARTEDAT DESC 
  LIMIT 1;
" 2>/dev/null) || { echo "error|"; exit 1; }

[[ -n "$RESULT" ]] || idle

IFS='|' read -r ACTIVITY_ID TYPE DURATION PROGRESSED STARTED <<< "$RESULT"

PAUSE_STATE=$(get_pause_state)

if [[ "$PAUSE_STATE" == "unknown" ]]; then
  echo "error|"
  exit 1
fi

if [[ "$PAUSE_STATE" == "paused" ]]; then
  mkdir -p "$CACHE_DIR"
  
  if [[ -f "$CACHE_FILE" ]]; then
    IFS='|' read -r CACHED_ACTIVITY_ID CACHED_STARTED CACHED_PROGRESSED CACHED_REMAINING RESUME_TS <<< "$(cat "$CACHE_FILE" 2>/dev/null || echo "||||")"
    CACHED_ACTIVITY_ID=${CACHED_ACTIVITY_ID:-}
    RESUME_TS=${RESUME_TS:-}
    
    CACHED_STARTED_INT=${CACHED_STARTED%.*}
    STARTED_INT=${STARTED%.*}
    CACHED_ZPROG_INT=${CACHED_PROGRESSED%.*}
    ZPROG_INT=${PROGRESSED%.*}
    
    if [[ "$CACHED_ACTIVITY_ID" == "$ACTIVITY_ID" && "$CACHED_STARTED_INT" == "$STARTED_INT" && "$CACHED_ZPROG_INT" == "$ZPROG_INT" && -n "$CACHED_REMAINING" ]]; then
      if [[ -z "$RESUME_TS" ]]; then
        REMAINING=$CACHED_REMAINING
      else
        NOW=$(date +%s)
        REMAINING=$((CACHED_REMAINING - (NOW - RESUME_TS)))
        [[ $REMAINING -gt 0 ]] || idle
      fi
      
      MINS=$((REMAINING / 60))
      SECS=$((REMAINING % 60))
      TIME_STR=$(printf "%02d:%02d" "$MINS" "$SECS")
      echo "${ACTIVITY_ID}|${STARTED}|${PROGRESSED}|${REMAINING}|" > "$CACHE_FILE"
      echo "paused_${TYPE}|${TIME_STR}"
      exit 0
    fi
  fi
  
  STARTED_INT=${STARTED%.*}
  STARTED_UNIX=$((STARTED_INT + CORE_DATA_EPOCH_OFFSET))
  REMAINING=$((DURATION - PROGRESSED - ($(date +%s) - STARTED_UNIX)))
  [[ $REMAINING -gt 0 ]] || idle
  
  MINS=$((REMAINING / 60))
  SECS=$((REMAINING % 60))
  TIME_STR=$(printf "%02d:%02d" "$MINS" "$SECS")
  echo "${ACTIVITY_ID}|${STARTED}|${PROGRESSED}|${REMAINING}|" > "$CACHE_FILE"
  echo "paused_${TYPE}|${TIME_STR}"
  exit 0
fi

if [[ -f "$CACHE_FILE" ]]; then
  IFS='|' read -r CACHED_ACTIVITY_ID CACHED_STARTED CACHED_PROGRESSED CACHED_REMAINING RESUME_TS <<< "$(cat "$CACHE_FILE" 2>/dev/null || echo "||||")"
  CACHED_ACTIVITY_ID=${CACHED_ACTIVITY_ID:-}
  RESUME_TS=${RESUME_TS:-}
  
  CACHED_STARTED_INT=${CACHED_STARTED%.*}
  STARTED_INT=${STARTED%.*}
  CACHED_ZPROG_INT=${CACHED_PROGRESSED%.*}
  ZPROG_INT=${PROGRESSED%.*}
  
  if [[ "$CACHED_ACTIVITY_ID" == "$ACTIVITY_ID" && "$CACHED_STARTED_INT" == "$STARTED_INT" && "$CACHED_ZPROG_INT" == "$ZPROG_INT" ]]; then
    NOW=$(date +%s)
    
    if [[ -z "$RESUME_TS" ]]; then
      RESUME_TS=$NOW
      echo "${ACTIVITY_ID}|${STARTED}|${PROGRESSED}|${CACHED_REMAINING}|${RESUME_TS}" > "$CACHE_FILE"
    fi
    
    REMAINING=$((CACHED_REMAINING - (NOW - RESUME_TS)))
    [[ $REMAINING -gt 0 ]] || { rm -f "$CACHE_FILE"; idle; }
  else
    rm -f "$CACHE_FILE"
    STARTED_INT=${STARTED%.*}
    STARTED_UNIX=$((STARTED_INT + CORE_DATA_EPOCH_OFFSET))
    REMAINING=$((DURATION - PROGRESSED - ($(date +%s) - STARTED_UNIX)))
    [[ $REMAINING -gt 0 ]] || idle
  fi
else
  STARTED_INT=${STARTED%.*}
  STARTED_UNIX=$((STARTED_INT + CORE_DATA_EPOCH_OFFSET))
  REMAINING=$((DURATION - PROGRESSED - ($(date +%s) - STARTED_UNIX)))
  [[ $REMAINING -gt 0 ]] || idle
fi

MINS=$((REMAINING / 60))
SECS=$((REMAINING % 60))
TIME_STR=$(printf "%02d:%02d" "$MINS" "$SECS")
echo "${TYPE}|${TIME_STR}"
