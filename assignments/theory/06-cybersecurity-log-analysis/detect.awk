# detect.awk - detections over the normalized event stream (events.txt).
# Usage: awk -F';' -v mode=brute|spray|compromise|offhours|hourly \
#            -v burst=10 -v window=300 -v spray_users=8 -v dawn=6 -v dusk=22 -f detect.awk events.txt
# POSIX awk only (no gawk extensions), so it runs on mawk, BSD awk and gawk.

function secs(d, t,    p, day) {          # "Oct 7", "02:14:00" -> seconds
    split(d, p, " "); day = p[2]
    split(t, hms, ":")
    return day * 86400 + hms[1] * 3600 + hms[2] * 60 + hms[3]
}
function internal(ip) { return ip ~ /^10\.0\.0\./ }

{
    d = $1; t = $2; ev = $4; user = $5; ip = $6
    s = secs(d, t)
    hr = substr(t, 1, 2) + 0
}

# --- failures: total, distinct usernames, sliding-window burst -------------------
ev ~ /^FAIL/ {
    fails[ip]++
    if (!((ip, user) in seen)) { seen[ip, user] = 1; nusers[ip]++ }
    if (!(ip in first)) first[ip] = d " " t
    last[ip] = d " " t

    n = ++cnt[ip]; stamp[ip, n] = s       # queue of failure times for this IP
    while (stamp[ip, head[ip] + 1] < s - window) head[ip]++
    inwin = n - head[ip]
    if (inwin > maxburst[ip]) maxburst[ip] = inwin
    if (ev == "FAIL_INVALID") invalid[ip]++
}

# --- successes: was this IP previously failing? ------------------------------------
ev ~ /^ACCEPT/ {
    acc++
    line[acc] = d " " t "|" user "|" ip "|" ev "|" fails[ip] + 0 "|" hr
}

# --- hourly histogram of failures (all IPs) -------------------------------------------
ev ~ /^FAIL/ { perhour[hr]++ }

END {
    if (mode == "brute") {
        printf "%-16s %6s %6s %-14s %-14s\n", "SOURCE_IP", "FAILS", "BURST", "FIRST_SEEN", "LAST_SEEN"
        for (ip in fails)
            if (maxburst[ip] >= burst)
                printf "%-16s %6d %6d %-14s %-14s\n", ip, fails[ip], maxburst[ip], first[ip], last[ip]
    }
    else if (mode == "spray") {
        printf "%-16s %6s %10s %8s\n", "SOURCE_IP", "FAILS", "USERNAMES", "BURST"
        for (ip in fails)
            if (nusers[ip] >= spray_users && maxburst[ip] < burst)
                printf "%-16s %6d %10d %8d\n", ip, fails[ip], nusers[ip], maxburst[ip]
    }
    else if (mode == "compromise") {
        printf "%-14s %-8s %-16s %-16s %s\n", "WHEN", "USER", "SOURCE_IP", "METHOD", "PRIOR_FAILS_FROM_IP"
        for (i = 1; i <= acc; i++) {
            split(line[i], f, "|")
            if (f[5] >= burst)
                printf "%-14s %-8s %-16s %-16s %s\n", f[1], f[2], f[3], f[4], f[5]
        }
    }
    else if (mode == "offhours") {
        printf "%-14s %-8s %-16s %-16s %-9s %s\n", "WHEN", "USER", "SOURCE_IP", "METHOD", "NETWORK", "SEVERITY"
        for (i = 1; i <= acc; i++) {
            split(line[i], f, "|")
            if (f[6] < dawn || f[6] >= dusk) {
                net = internal(f[3]) ? "internal" : "external"
                sev = (net == "external") ? "HIGH" : "LOW"
                printf "%-14s %-8s %-16s %-16s %-9s %s\n", f[1], f[2], f[3], f[4], net, sev
            }
        }
    }
    else if (mode == "hourly") {
        for (hh = 0; hh < 24; hh++) {
            c = perhour[hh] + 0
            bar = ""; for (k = 0; k < c / 10; k++) bar = bar "#"
            printf "%02d:00 %5d %s\n", hh, c, bar
        }
    }
}
