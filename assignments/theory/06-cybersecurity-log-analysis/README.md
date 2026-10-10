# Theory 06: SSH log analysis with Linux tools

Detects brute force, password spraying, a successful login after brute force,
and off-hours logins in an OpenSSH `auth.log`, using `grep`, `sed`, `awk` and
Bash only.

## Files

| File | Purpose |
| :-- | :-- |
| `auth.log` | The log analysed (1,031 lines, synthetic, see below) |
| `generate_log.py` | Seeded generator that produced `auth.log` |
| `analyze.sh` | Main Bash script; runs every step |
| `normalize.sed` | sed script: raw sshd lines to `DATE;TIME;PID;EVENT;USER;IP` |
| `detect.awk` | awk script: brute force, spray, compromise, off-hours, hourly counts |
| `outputs/report.txt` | Full output of `analyze.sh` |
| `outputs/events.txt` | Normalized events (sed output) |
| `outputs/*.txt` | Extra runs used in the report (naive threshold, `BURST=3`, event mix) |
| `main.typ` | Typst source of the assignment report |

## Requirements

Bash, `grep`, `sed -E`, `awk`, `sort`, `uniq`, `cut`, `head`, `tail`, `wc`, `tr`.
Output in `outputs/` was produced on Debian 12 (GNU sed 4.9, grep 3.8, mawk
1.3.4). The awk script uses POSIX features only, so gawk and macOS awk also work.
Python 3 is needed only to regenerate the log.

## Run

```bash
cd assignments/theory/06-cybersecurity-log-analysis
chmod +x analyze.sh
./analyze.sh                      # uses auth.log, writes outputs/
./analyze.sh auth.log outputs     # same, explicit
BURST=3 ./analyze.sh auth.log /tmp/try   # change a threshold
python3 generate_log.py           # optional: rebuild auth.log (identical every time)
```

Thresholds (environment variables): `BURST=10`, `WINDOW=300` (seconds),
`SPRAY_USERS=8`, `DAWN=6`, `DUSK=22`.

## Dataset source

Simulated. No download. `generate_log.py` writes an OpenSSH log in the format of
`/var/log/auth.log` on Debian/Ubuntu. Hostname, users and addresses are invented;
public-looking addresses come from the RFC 5737 documentation ranges
(`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`). No real or third-party
system was scanned or attacked, and the file holds no real passwords, tokens or
personal data. Generated on 2026-10-09.

## External resources and assistance

- `man` pages for `grep`, `sed`, `awk`, `sort`, `uniq`.
- OpenSSH `sshd` log message formats and the MITRE ATT&CK techniques T1110.001
  (password guessing), T1110.003 (password spraying) and T1078 (valid accounts).
- RFC 5737 for the documentation address ranges.
- Claude (Anthropic) was used to draft the generator and scripts; the commands
  were run and the outputs checked by the author.
