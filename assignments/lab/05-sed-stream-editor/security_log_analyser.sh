#!/bin/bash
# security_log_analyser.sh - build a redacted alert report from an auth log.
# Usage: ./security_log_analyser.sh <logfile>

REPORT="security_alert_report.txt"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <logfile>" >&2
    exit 1
fi

LOG="$1"

if [ ! -f "$LOG" ]; then
    echo "Error: file '$LOG' does not exist." >&2
    exit 2
fi

if [ ! -r "$LOG" ]; then
    echo "Error: file '$LOG' is not readable." >&2
    exit 3
fi

# Keep only failed logins and invalid-user attempts, mask every IPv4
# address and put [ALERT] in front of each remaining entry.
EVENTS=$(sed -n -E '/Failed password|Invalid user/{
    s/([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED_IP]/g
    s/^/[ALERT] /
    p
}' "$LOG")

if [ -z "$EVENTS" ]; then
    EVENTS="No failed-login or invalid-user events found."
fi

# Add the heading and the closing line, then save the report.
printf '%s\n' "$EVENTS" |
    sed -e '1i SECURITY ALERT REPORT' -e '$a END OF REPORT' > "$REPORT"

cat "$REPORT"
