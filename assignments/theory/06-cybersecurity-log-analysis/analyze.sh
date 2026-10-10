#!/usr/bin/env bash
# analyze.sh - SSH authentication log analysis (power filters + sed + awk).
# Usage: ./analyze.sh [logfile] [outdir]
set -euo pipefail

LOG="${1:-auth.log}"
OUT="${2:-outputs}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Thresholds, overridable from the environment.
BURST="${BURST:-10}"              # failures inside WINDOW that count as brute force
WINDOW="${WINDOW:-300}"           # seconds
SPRAY_USERS="${SPRAY_USERS:-8}"   # distinct usernames tried from one IP
DAWN="${DAWN:-6}"                 # logins before this hour are off-hours
DUSK="${DUSK:-22}"                # logins at or after this hour are off-hours

# --- 0. input checks (file test operators) -----------------------------------------
[ -f "$LOG" ] || { echo "Error: '$LOG' is not a regular file." >&2; exit 1; }
[ -r "$LOG" ] || { echo "Error: '$LOG' is not readable." >&2; exit 1; }
[ -s "$LOG" ] || { echo "Error: '$LOG' is empty." >&2; exit 1; }
mkdir -p "$OUT"

section() { printf '\n==== %s ====\n' "$1"; }

{
section "1. Overview (grep / wc / cut / sort / uniq)"
echo "Total lines:            $(wc -l < "$LOG" | tr -d ' ')"
echo "sshd lines:             $(grep -c 'sshd\[' "$LOG")"
echo "Failed passwords:       $(grep -c 'Failed password' "$LOG")"
echo "  for invalid users:    $(grep -c 'Failed password for invalid user' "$LOG")"
echo "Accepted logins:        $(grep -c 'Accepted ' "$LOG")"
echo "sudo commands:          $(grep -c 'sudo:' "$LOG")"
echo "Time span:              $(head -n1 "$LOG" | cut -c1-15)  ->  $(tail -n1 "$LOG" | cut -c1-15)"

section "2. Top 5 source IPs by failed passwords (pipeline)"
grep 'Failed password' "$LOG" \
  | grep -oE 'from [0-9]+(\.[0-9]+){3}' \
  | cut -d' ' -f2 \
  | sort | uniq -c | sort -rn | head -n 5

section "3. Top 8 usernames targeted"
grep 'Failed password' "$LOG" \
  | sed -E 's/.*Failed password for (invalid user )?([^ ]+) from.*/\2/' \
  | sort | uniq -c | sort -rn | head -n 8

# --- 4. normalize with sed ------------------------------------------------------------
sed -E -f "$HERE/normalize.sed" "$LOG" > "$OUT/events.txt"
section "4. Normalized events (sed) - $(wc -l < "$OUT/events.txt" | tr -d ' ') records, first 4 shown"
head -n 4 "$OUT/events.txt"

# --- 5. detections with awk ------------------------------------------------------------
run_awk() {
  awk -F';' -v mode="$1" -v burst="$BURST" -v window="$WINDOW" \
      -v spray_users="$SPRAY_USERS" -v dawn="$DAWN" -v dusk="$DUSK" \
      -f "$HERE/detect.awk" "$OUT/events.txt"
}

section "5a. Brute force: >= $BURST failures within $WINDOW s"
run_awk brute | { read -r hdr; echo "$hdr"; sort -k2,2nr; }

section "5b. Low-and-slow spraying: >= $SPRAY_USERS distinct usernames, burst below $BURST"
run_awk spray | { read -r hdr; echo "$hdr"; sort -k2,2nr; }

section "5c. Possible compromise: successful login from an IP with >= $BURST prior failures"
run_awk compromise

section "5d. Off-hours logins (before ${DAWN}:00 or after ${DUSK}:00)"
run_awk offhours

section "5e. Failed logins per hour of day (# = 10 failures)"
run_awk hourly

# --- 6. privileged activity (grep + sed + awk) -------------------------------------------
section "6. sudo commands touching sensitive targets"
grep 'sudo:' "$LOG" \
  | sed -E 's/^([A-Z][a-z]{2}) +([0-9]+) ([0-9:]{8}) [^ ]+ sudo: +([^ ]+) : .*COMMAND=(.*)$/\1 \2;\3;\4;\5/' \
  | awk -F';' '
      $4 ~ /shadow|passwd|useradd|usermod|sshd|tar czf|chmod 777/ {
        printf "%-6s %-8s %-8s %s\n", $1, $2, $3, $4; n++ }
      END { print n + 0 " sensitive command(s)" }'

section "7. Summary of flagged sources"
{
  run_awk brute  | awk 'NR>1 {print $1 ",brute-force"}'
  run_awk spray  | awk 'NR>1 {print $1 ",password-spray"}'
  run_awk compromise | awk 'NR>1 {print $(NF-2) ",login-after-brute-force"}'
  run_awk offhours   | awk 'NR>1 && $NF=="HIGH" {print $(NF-3) ",external-off-hours-login"}'
} | sort -t, -k1,1 -k2,2 -u | awk -F, '{r[$1] = r[$1] (r[$1] ? ", " : "") $2}
      END {for (ip in r) printf "%-16s %s\n", ip, r[ip]}' | sort
} | tee "$OUT/report.txt"
