# normalize.sed - turn raw sshd lines into semicolon-separated events:
#   DATE;TIME;PID;EVENT;USER;SRC_IP
# Works with GNU and BSD sed (run with -E).

# 1. keep only sshd lines
/ sshd\[[0-9]+\]: /!d

# 2. split the syslog prefix: "Oct  7 02:14:00 labhost sshd[1391]: "
s/^([A-Z][a-z]{2}) +([0-9]+) ([0-9:]{8}) [^ ]+ sshd\[([0-9]+)\]: /\1 \2;\3;\4;/

# 3. rewrite each message type into EVENT;USER;IP
s/;Failed password for invalid user ([^ ]+) from ([0-9.]+) port [0-9]+ ssh2$/;FAIL_INVALID;\1;\2/
s/;Failed password for ([^ ]+) from ([0-9.]+) port [0-9]+ ssh2$/;FAIL;\1;\2/
s/;Accepted (password|publickey) for ([^ ]+) from ([0-9.]+) port [0-9]+ ssh2$/;ACCEPT_\1;\2;\3/

# 4. drop anything that did not become an event (noise, session lines, probes)
/^[A-Z][a-z]{2} [0-9]+;[0-9:]{8};[0-9]+;(FAIL|FAIL_INVALID|ACCEPT_password|ACCEPT_publickey);/!d
