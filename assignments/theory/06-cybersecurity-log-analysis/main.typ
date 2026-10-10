#import "/template/lib.typ": *

#show: assignment.with(
  title: "Cybersecurity Log Analysis Using Linux Tools",
  number: "Assignment 06",
  kind: "Theory",
  keywords: ("ssh", "brute force", "password spraying", "grep", "sed", "awk", "bash"),
  date: datetime(year: 2026, month: 10, day: 10),
)

#set heading(numbering: "1.")

= Scenario and security significance

The scenario is *SSH authentication attacks against a Linux server*. An internet-facing
`sshd` is probed constantly. The attacks of interest here are:

- *Brute force*: many password guesses from one address in a short time (MITRE ATT\&CK T1110.001).
- *Password spraying*: one or two guesses per account across many accounts, slowly, to stay under lockout and rate limits (T1110.003).
- *Use of a guessed credential*: a successful login from an address that was failing a moment earlier (T1078, valid accounts).
- *Suspicious access*: logins at unusual hours from outside the internal network, followed by privileged commands.

It matters because SSH is the main remote door to a Linux host. A single guessed
password gives an attacker a shell, and `sudo` turns that into full control.
`/var/log/auth.log` is usually the first and sometimes the only evidence.

= How the log was obtained

The log is *simulated*. No download and no live system was involved.

- *Environment*: the author's own laptop. No network traffic was generated, and no
  host was scanned or tested.
- *Tool*: `generate_log.py`, a Python 3 script with a fixed random seed
  (`random.seed(2026)`), so the same file comes out every run.
- *Procedure*: the script writes lines in the exact format OpenSSH and `sudo` use
  in `/var/log/auth.log` on Debian/Ubuntu. It first writes normal staff activity,
  then three planted incidents (Section 6), then sorts everything by time.
- *Safety*: hostname, users and addresses are invented. The public-looking
  addresses are from the RFC 5737 documentation ranges (`192.0.2.0/24`,
  `198.51.100.0/24`, `203.0.113.0/24`), which are reserved and cannot belong to a
  real host. The file holds no real password, token or personal data.
- *Date generated*: 9 October 2026.

Because the file is synthetic, the results show that the method works on the
patterns planted in it. They do not measure how often these rules fire on a real
server (see Section 10).

= Structure of the log

`auth.log` has 1,031 lines. Each line is one syslog record:

```text
Oct  7 02:14:02 labhost sshd[1653]: Failed password for root from 203.0.113.45 port 41872 ssh2
```

#table(
  columns: (auto, 1fr),
  align: (left, left),
  [*Field*], [*Meaning*],
  [`Oct  7 02:14:02`], [Timestamp (month, day, time). Syslog has no year, and the day is padded with a space, so a single-digit day has two spaces before it.],
  [`labhost`], [Host that wrote the record.],
  [`sshd[1653]`], [Program and process ID. One connection attempt keeps one PID, so a PID ties together the lines of one attempt.],
  [`Failed password for [invalid user] NAME`], [A rejected password. `invalid user` means the account does not exist, which points to guessing or enumeration.],
  [`Accepted password|publickey for NAME`], [A successful login and the method used.],
  [`from 203.0.113.45 port 41872`], [Source address and ephemeral port. The address is the key field for every detection.],
  [`pam_unix(sshd:session)`], [Session opened and closed lines.],
  [`sudo: NAME : ... COMMAND=...`], [Privileged command run by a user.],
)

Line types present: failed password (502), accepted login (30), session open/close,
`Invalid user` pre-auth lines, `Connection closed ... [preauth]`, `Did not receive
identification string` (scanner noise), and 5 `sudo` lines.

= Investigation questions

+ *Q1.* Which source addresses made enough failed logins in a short window to be brute-forcing?
+ *Q2.* Which addresses are guessing across many usernames slowly (password spraying)?
+ *Q3.* Did any address that was failing later log in successfully, and what did that account do afterwards?
+ *Q4.* Were there successful logins at unusual hours or from outside the internal network?
+ *Q5.* Which usernames are attackers targeting, and when is failure activity highest?

= Tools and design

#table(
  columns: (auto, 1fr),
  align: (left, left),
  [*Tool*], [*Used for*],
  [Power filters / pipelines], [`grep`, `cut`, `sort | uniq -c | sort -rn | head` for counts, top-N tables and the sudo filter.],
  [`sed` (`normalize.sed`)], [Throw away irrelevant lines and rewrite each sshd message into one `;`-separated record.],
  [`awk` (`detect.awk`)], [Stateful logic that filters cannot do: per-IP counters, sliding time window, distinct usernames, comparing a success against earlier failures.],
  [Bash (`analyze.sh`)], [Input checks, thresholds as variables, running every step in order, saving the report with `tee`.],
)

The flow is: raw log #sym.arrow `grep`/`sort`/`uniq` overview #sym.arrow `sed` normalises #sym.arrow
`awk` detects #sym.arrow Bash prints one report. Thresholds live in Bash variables and are passed
to `awk` with `-v`, so they can be changed without editing the awk file.

= Scripts and what each command does

== `normalize.sed`

#code(read("normalize.sed"), file: "normalize.sed")

- `/ sshd\[[0-9]+\]: /!d` deletes every line that is not from `sshd` (the `sudo` lines are handled separately).
- The first `s///` splits the syslog prefix. `+` after the space absorbs the double space of single-digit days, and the groups become `Oct 7;02:14:02;1653;`.
- The three following `s///` rewrite each message into `EVENT;USER;IP`. The more specific `invalid user` pattern comes first, otherwise `Failed password for invalid` would be read as a user called `invalid`.
- The last `/.../!d` deletes any line that did not become an event: `Connection closed`, `Invalid user` pre-auth lines, session lines and probes. Those are noise for these questions.

== `detect.awk`

#code(read("detect.awk"), file: "detect.awk")

- `-F';'` splits the normalized records into `$1`..`$6`. `-v mode=` selects one report, so one file serves five detections.
- `secs()` turns day and time into seconds so windows can be measured. It assumes all events are in one month (true for this log).
- The `ev ~ /^FAIL/` rule counts failures per IP (`fails[ip]`), counts distinct usernames (`seen[ip,user]`, `nusers[ip]`), and keeps a queue of failure times per IP. The `while` loop moves the queue head past failures older than `window`, so `n - head` is the number of failures in the last 5 minutes, and `maxburst[ip]` keeps the largest.
- The `ev ~ /^ACCEPT/` rule stores each success with the number of failures that IP had made *before that moment*. This works because the log is in time order.
- `END` prints the section chosen by `mode`.

== `analyze.sh`

#code(read("analyze.sh"), file: "analyze.sh")

- `set -euo pipefail` stops on an error, an unset variable, or a failure inside a pipe.
- `"${1:-auth.log}"` and `"${BURST:-10}"` give defaults that arguments or the environment can override.
- `[ -f ]`, `[ -r ]`, `[ -s ]` check the log exists, is readable and is not empty before anything runs.
- `grep -c`, `wc -l`, `head`, `tail`, `cut -c1-15` build the overview. Pipeline 2 is `grep 'Failed password' | grep -oE 'from <ip>' | cut -d' ' -f2 | sort | uniq -c | sort -rn | head -n 5`: `-o` keeps only the matched part, `cut` drops the word `from`, `sort | uniq -c` groups identical addresses, `sort -rn` ranks by count.
- Pipeline 3 uses `sed -E` with `(invalid user )?` to pull out the username in both message forms.
- `sed -E -f normalize.sed` writes `outputs/events.txt`; everything after reads that file.
- `run_awk` wraps the awk call. `{ read -r hdr; echo "$hdr"; sort ...; }` prints the header line first and sorts only the data rows.
- Section 6 chains `grep 'sudo:'`, a `sed` that keeps date, user and command, and an `awk` that prints only commands matching a sensitive-target pattern and counts them.
- Section 7 merges the detections into one `ip,label` list, removes duplicates with `sort -u`, and `awk` joins the labels per IP.
- `tee` shows the report and saves it to `outputs/report.txt` at once.

= Output and findings

All output below is from `./analyze.sh` run on Debian 12 (GNU sed 4.9, grep 3.8, mawk 1.3.4). The full text is in `outputs/report.txt`.

== Overview and top talkers

#let out(body) = raw(body.trim("\n"), block: true)
#out(read("outputs/report.txt").split("==== 4.").first().trim())

*Reading it.* 502 failed passwords, 405 of them for accounts that do not exist. One
address, `203.0.113.45`, made 420 of the 502 failures (84%). The usernames at the
top (`admin`, `root`, `guest`, `test`, `oracle`) are standard dictionary guesses.

== Normalized events (sed output)

#out(read("outputs/report.txt").split("==== 4.").last().split("==== 5a.").first().trim())

The 1,031 raw lines reduce to 532 events (502 failures and 30 successes). Every later step reads this smaller, uniform file.

== Brute force, spraying, compromise, off-hours

#out("==== 5a." + read("outputs/report.txt").split("==== 5a.").last().split("==== 5e.").first().trim())

== Failures per hour

#out("==== 5e." + read("outputs/report.txt").split("==== 5e.").last().split("==== 6.").first().trim())

The spike at 02:00 (422 of 502 failures) is the brute-force run. Every other hour has 9 failures or fewer, which is the normal level of typos and background probing.

== Privileged activity and summary

#out("==== 6." + read("outputs/report.txt").split("==== 6.").last().trim())

== Suspicious records and patterns

#table(
  columns: (auto, auto, 1fr),
  align: (left, left, left),
  [*Source*], [*Verdict*], [*Evidence*],
  [`203.0.113.45`], [Compromise], [420 failures over 14 minutes (02:14:00 to 02:27:59), 14 usernames, up to 159 failures in 5 minutes. At 02:28:08, nine seconds after the last failure, `deploy` logs in *by password* from this address. `deploy` otherwise logs in from `10.0.0.x`. Within about two minutes `deploy` runs `cat /etc/shadow`, `useradd -m svc_backup` and restarts `sshd`: credential theft, a new backdoor account and a service restart.],
  [`198.51.100.77`], [Password spray], [24 failures, 12 usernames, two rounds, about 10 minutes between attempts, over roughly four hours. The largest 5-minute burst is 1, so a rate rule never fires. No success from this address.],
  [`192.0.2.88`], [Suspicious access], [`alice` logs in by key at 03:41 on Oct 8 from an external address, then runs `tar czf /tmp/home.tgz /home` at 03:41:34, which looks like staging data for exfiltration. No failures precede it, so a stolen key is more likely than a guessed password.],
)

= Why these thresholds

#table(
  columns: (auto, auto, 1fr),
  align: (left, left, left),
  [*Rule*], [*Threshold*], [*Justification*],
  [Brute force], [#sym.gt.eq 10 failures in 300 s], [A person mistypes a password once or twice. Ten failures in five minutes (one every 30 s) is beyond human error and under the automated rate seen here (159 per 5 minutes). Using a window, not a total, is what separates a burst from slow accumulation (see below).],
  [Spray], [#sym.gt.eq 8 distinct usernames, burst below 10], [One person has one or two accounts. Eight different names from one address is guessing. Requiring a low burst keeps this rule for the slow attacker and avoids reporting the brute-forcer twice.],
  [Compromise], [Success with #sym.gt.eq 10 earlier failures from that IP], [A legitimate user who fails ten times would normally lock or reset. A success after ten failures from the same address is the point where a guess worked.],
  [Off-hours], [Before 06:00 or from 22:00], [Outside normal working time for this staff. Rated *HIGH* only when the address is not in `10.0.0.0/24`, because a late login from the office network alone is low risk.],
  [Sensitive sudo], [Pattern list], [`shadow`, `passwd`, `useradd`, `usermod`, `sshd`, `tar czf`, `chmod 777` touch credentials, accounts, remote access, or bulk copying.],
)

The thresholds are judgement calls. They were checked against the planted normal
behaviour in Section 9, not tuned to a real baseline.

= False positives and limitations

*Why a window and not a total.* A naive rule, "10 or more failures in the whole log", gives:

#out(read("outputs/naive_total_ge10.txt"))

`192.0.2.10` is the office NAT gateway. Twelve different people mistyped over two days, which is harmless. The 5-minute window ignores it because its largest burst is 1.

*Lowering the threshold.* Re-running with `BURST=3` gives:

#out(read("outputs/sensitivity_burst3.txt"))

`10.0.0.23` is `bob`, who forgot his password after a holiday: four failures in 33 seconds, then a success. At `BURST=3` he is flagged. At the chosen 10 he is not. A lower threshold catches slower attackers and costs more false alarms.

*Other possible false positives:*

- A vulnerability scanner or monitoring probe run by the owner looks like a brute force.
- A script with a stale password (backup job, CI runner) fails repeatedly from one fixed address.
- Off-hours rules flag on-call staff, people travelling, and anyone on VPN or a mobile network.
- Many users behind one NAT or proxy share an address, so per-IP counts mix people.

*Limitations:*

- *Synthetic data.* The log has clean, planted patterns. A real log has more noise, and rates and thresholds would need tuning on a baseline of that server.
- *Missed attacks.* An attacker who stays below 8 usernames and tries one password every few hours is invisible to these rules. A distributed attack (each address trying a few times) is missed because everything is counted per IP.
- *Stolen keys and valid credentials.* The `192.0.2.88` case is flagged only by time and network. A key used at 14:00 from a known address would pass unnoticed.
- *No year, one month.* Syslog has no year, and `secs()` assumes one month, so a log crossing a month end would give wrong windows. Timestamps are also in the server's local zone.
- *IPv6 and other services.* The IPv4 regexes ignore IPv6, and only `sshd` and `sudo` are read.
- *Evidence, not proof.* The output points to what to inspect next (session recording, `last`, file integrity of `/etc/passwd`). It does not prove intent.
- *Response.* For the flagged cases the next steps would be: disable `deploy` and `svc_backup`, rotate the `deploy` password, enforce key-only SSH (`PasswordAuthentication no`), add `fail2ban` or rate limiting, and review what `alice`'s session read.

= Resources and assistance

- Manual pages: `grep`, `sed`, `awk`, `sort`, `uniq`, `cut`, `tee`.
- MITRE ATT\&CK: T1110.001, T1110.003, T1078.
- RFC 5737 (documentation address ranges).
- Class material on filters, `sed`, `awk` and Bash scripting.
- Claude (Anthropic) assisted with drafting the generator, scripts and report text. All scripts were executed and the results above are their actual output.

= Submission files

`main.typ` (this report), `auth.log`, `generate_log.py`, `analyze.sh`, `normalize.sed`, `detect.awk`, `outputs/` (`report.txt`, `events.txt`, `naive_total_ge10.txt`, `sensitivity_burst3.txt`, `event_mix.txt`) and `README.md`. The dataset is simulated (Section 2), so there is no external download.
