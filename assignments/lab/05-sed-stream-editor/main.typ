#import "/template/lib.typ": *
#import "@preview/codly:1.3.0" as codly

#show: assignment.with(
  title: "sed Stream Editor for Security Log Analysis",
  number: "Assignment 05",
  kind: "Lab",
  date: datetime(year: 2026, month: 9, day: 22),
)

#let out(body) = codly.local(number-format: none)[#raw(body.trim("\n"), block: true)]
#let q(desc, cmd, res: none) = block(above: 0.7em, below: 0.4em, breakable: true, {
  desc
  v(2pt)
  codly.local(number-format: none)[#cmd]
  if res != none { out(res) }
})

= Aim

Use the `sed` stream editor to print, filter, delete, substitute, insert,
append and save lines of an authentication log and a web-server log, then
combine those operations in a script file, a configuration edit and a Bash
analyser. Every command in this record was run from inside
`05-sed-stream-editor/` on a Linux shell with GNU `sed` 4.9, and the output
shown is the output the command produced.

== Files in the working directory

`auth.log` holds 10 SSH and sudo events from 10 September: three accepted
passwords, four failed passwords, one invalid user, one sudo authentication
failure and one closed connection.

`access.log` holds 10 web requests in the form `source - METHOD URL status`:
four with status 200, three with 401 and three with 403. Three of the blocked
requests are attacks, a SQL injection, a path traversal and a script injection.

`sed` reads its input one line at a time, applies the commands to that line and
writes the result to standard output. The input file is never altered unless
`-i` is given, which is why every example below can be repeated on the same
file.

= Part A: Authentication log

== Exercise 1: Printing lines

`-n` switches off the automatic printing of every line, so `p` prints only the lines an address selects. Without `-n` each selected line would appear twice.

#q([1. First entry.],
```bash
sed -n '1p' auth.log
```,
res: read("outputs/e1_1.txt"))

#q([2. Fifth entry.],
```bash
sed -n '5p' auth.log
```,
res: read("outputs/e1_2.txt"))

#q([3. Lines 2 to 6.],
```bash
sed -n '2,6p' auth.log
```,
res: read("outputs/e1_3.txt"))

#q([4. Last entry. `$` addresses the last line.],
```bash
sed -n '$p' auth.log
```,
res: read("outputs/e1_4.txt"))

#q([5. Every second entry starting at line 1. `first~step` is a GNU extension.],
```bash
sed -n '1~2p' auth.log
```,
res: read("outputs/e1_5.txt"))

#q([6. Entries containing `Failed password`.],
```bash
sed -n '/Failed password/p' auth.log
```,
res: read("outputs/e1_6.txt"))

#q([7. Successful logins.],
```bash
sed -n '/Accepted password/p' auth.log
```,
res: read("outputs/e1_7.txt"))

#q([8. From the first failed login to the authentication failure. A range with two patterns starts at the first line matching the first pattern and ends at the next line matching the second.],
```bash
sed -n '/Failed password/,/authentication failure/p' auth.log
```,
res: read("outputs/e1_8.txt"))

== Exercise 2: Filtering security events

Dots in an IP address are escaped, since an unescaped `.` matches any character.

#q([1. Failed login attempts.],
```bash
sed -n '/Failed password/p' auth.log
```,
res: read("outputs/e2_1.txt"))

#q([2. Successful login attempts.],
```bash
sed -n '/Accepted password/p' auth.log
```,
res: read("outputs/e2_2.txt"))

#q([3. Entries for the root account.],
```bash
sed -n '/root/p' auth.log
```,
res: read("outputs/e2_3.txt"))

#q([4. Entries containing `Invalid user`.],
```bash
sed -n '/Invalid user/p' auth.log
```,
res: read("outputs/e2_4.txt"))

#q([5. Every event involving `172.16.0.8`.],
```bash
sed -n '/172\.16\.0\.8/p' auth.log
```,
res: read("outputs/e2_5.txt"))

#q([6. Everything except `Accepted password`. `!` negates the address.],
```bash
sed -n '/Accepted password/!p' auth.log
```,
res: read("outputs/e2_6.txt"))

#q([7. Everything except the sudo events.],
```bash
sed -n '/sudo/!p' auth.log
```,
res: read("outputs/e2_7.txt"))

#q([8. `Failed password` or `Invalid user`, using one `-e` per pattern.],
```bash
sed -n -e '/Failed password/p' -e '/Invalid user/p' auth.log
```,
res: read("outputs/e2_8.txt"))

== Exercise 3: Removing irrelevant entries

`d` deletes the pattern space and starts the next cycle. The original file is never changed, because `sed` only writes to standard output unless `-i` is used.

#q([1. Delete successful logins.],
```bash
sed '/Accepted password/d' auth.log
```,
res: read("outputs/e3_1.txt"))

#q([2. Delete `Connection closed` entries.],
```bash
sed '/Connection closed/d' auth.log
```,
res: read("outputs/e3_2.txt"))

#q([3. Delete the first three entries.],
```bash
sed '1,3d' auth.log
```,
res: read("outputs/e3_3.txt"))

#q([4. Delete lines 4 to 7.],
```bash
sed '4,7d' auth.log
```,
res: read("outputs/e3_4.txt"))

#q([5. Delete everything associated with `192.168.1.15`.],
```bash
sed '/192\.168\.1\.15/d' auth.log
```,
res: read("outputs/e3_5.txt"))

#q([6. Delete every second entry starting from line 1.],
```bash
sed '1~2d' auth.log
```,
res: read("outputs/e3_6.txt"))

#q([7. Delete every line that is not a failed login.],
```bash
sed '/Failed password/!d' auth.log
```,
res: read("outputs/e3_7.txt"))

#q([The file is unchanged after all of the above.],
```bash
wc -l auth.log
```,
res: read("outputs/e3_8.txt"))

== Exercise 4: Classifying security events

These use `s/old/new/`. The `g` flag replaces every match on a line rather than only the first.

#q([1. `Accepted password` becomes `[SUCCESSFUL LOGIN]`.],
```bash
sed 's/Accepted password/[SUCCESSFUL LOGIN]/' auth.log
```,
res: read("outputs/e4_1.txt"))

#q([2. `Failed password` becomes `[FAILED LOGIN]`.],
```bash
sed 's/Failed password/[FAILED LOGIN]/' auth.log
```,
res: read("outputs/e4_2.txt"))

#q([3. `Invalid user` becomes `[INVALID USER]`.],
```bash
sed 's/Invalid user/[INVALID USER]/' auth.log
```,
res: read("outputs/e4_3.txt"))

#q([4. `authentication failure` becomes `[AUTHENTICATION FAILURE]`.],
```bash
sed 's/authentication failure/[AUTHENTICATION FAILURE]/' auth.log
```,
res: read("outputs/e4_4.txt"))

#q([5. `root` becomes `PRIVILEGED_USER`.],
```bash
sed 's/root/PRIVILEGED_USER/g' auth.log
```,
res: read("outputs/e4_5.txt"))

#q([6. `server` becomes `authentication-server`.],
```bash
sed 's/server/authentication-server/g' auth.log
```,
res: read("outputs/e4_6.txt"))

== Exercise 5: Masking sensitive information

#q([1. `10.0.0.25` becomes `X.X.X.X`.],
```bash
sed 's/10\.0\.0\.25/X.X.X.X/g' auth.log
```,
res: read("outputs/e5_1.txt"))

#q([2. `172.16.0.8` becomes `SUSPICIOUS_IP`.],
```bash
sed 's/172\.16\.0\.8/SUSPICIOUS_IP/g' auth.log
```,
res: read("outputs/e5_2.txt"))

#q([3. The username `admin` becomes `USER_A`. `\b` keeps the match to the whole word.],
```bash
sed 's/\badmin\b/USER_A/g' auth.log
```,
res: read("outputs/e5_3.txt"))

#q([4. The username `student` becomes `USER_B`.],
```bash
sed 's/\bstudent\b/USER_B/g' auth.log
```,
res: read("outputs/e5_4.txt"))

#q([5. Every digit becomes `X`. The timestamps and process IDs are masked along with the addresses.],
```bash
sed 's/[0-9]/X/g' auth.log
```,
res: read("outputs/e5_5.txt"))

#q([6. Periods inside an IP address become hyphens. Four captured groups keep the timestamps, which contain colons rather than periods, untouched.],
```bash
sed -E 's/([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/\1-\2-\3-\4/g' auth.log
```,
res: read("outputs/e5_6.txt"))

#q([7. Every IPv4 address becomes `[REDACTED_IP]`.],
```bash
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED_IP]/g' auth.log
```,
res: read("outputs/e5_7.txt"))

= Part B: Web-server log

== Exercise 6: Filtering web requests

In `access.log` the status code is the last field, so ` 200$` anchors it to the end of the line and cannot match a number inside a URL.

#q([1. Status 200.],
```bash
sed -n '/ 200$/p' access.log
```,
res: read("outputs/e6_1.txt"))

#q([2. Status 401.],
```bash
sed -n '/ 401$/p' access.log
```,
res: read("outputs/e6_2.txt"))

#q([3. Status 403.],
```bash
sed -n '/ 403$/p' access.log
```,
res: read("outputs/e6_3.txt"))

#q([4. Requests to `/admin/login`. The slashes are escaped so they are not read as the end of the pattern.],
```bash
sed -n '/\/admin\/login/p' access.log
```,
res: read("outputs/e6_4.txt"))

#q([5. POST requests.],
```bash
sed -n '/POST/p' access.log
```,
res: read("outputs/e6_5.txt"))

#q([6. Path traversal, `../`.],
```bash
sed -n '/\.\.\//p' access.log
```,
res: read("outputs/e6_6.txt"))

#q([7. Script injection, `<script>`.],
```bash
sed -n '/<script>/p' access.log
```,
res: read("outputs/e6_7.txt"))

#q([8. SQL injection, `OR`.],
```bash
sed -n '/OR/p' access.log
```,
res: read("outputs/e6_8.txt"))

#q([9. Everything except successful requests.],
```bash
sed -n '/ 200$/!p' access.log
```,
res: read("outputs/e6_9.txt"))

#q([10. Requests from `10.0.0.25`. The `^` ties the match to the source field at the start of the line.],
```bash
sed -n '/^10\.0\.0\.25/p' access.log
```,
res: read("outputs/e6_10.txt"))

== Exercise 7: Labelling suspicious web requests

#q([1. Status 200 becomes `[ALLOWED]`.],
```bash
sed 's/ 200$/ [ALLOWED]/' access.log
```,
res: read("outputs/e7_1.txt"))

#q([2. Status 401 becomes `[UNAUTHORIZED]`.],
```bash
sed 's/ 401$/ [UNAUTHORIZED]/' access.log
```,
res: read("outputs/e7_2.txt"))

#q([3. Status 403 becomes `[BLOCKED]`.],
```bash
sed 's/ 403$/ [BLOCKED]/' access.log
```,
res: read("outputs/e7_3.txt"))

#q([4. `/admin/login` becomes `/RESTRICTED_RESOURCE`. Using `|` as the delimiter avoids escaping the slashes.],
```bash
sed 's|/admin/login|/RESTRICTED_RESOURCE|' access.log
```,
res: read("outputs/e7_4.txt"))

#q([5. `GET` becomes `READ_REQUEST`.],
```bash
sed 's/GET/READ_REQUEST/' access.log
```,
res: read("outputs/e7_5.txt"))

#q([6. `POST` becomes `SUBMIT_REQUEST`.],
```bash
sed 's/POST/SUBMIT_REQUEST/' access.log
```,
res: read("outputs/e7_6.txt"))

== Exercise 8: Grouping security operations

A `{ }` block runs several commands on every line its address selects. The commands inside are separated by `;`.

#q([1. Status 401: relabel it and print only those lines.],
```bash
sed -n '/ 401$/{s/ 401$/ [UNAUTHORIZED]/;p}' access.log
```,
res: read("outputs/e8_1.txt"))

#q([2. Status 403: relabel it, mask the source address and print.],
```bash
sed -n -E '/ 403$/{s/ 403$/ [BLOCKED]/;s/^([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED_IP]/;p}' access.log
```,
res: read("outputs/e8_2.txt"))

#q([3. Requests to `/admin/login`: replace the URL, mask the source and print.],
```bash
sed -n -E '/\/admin\/login/{s|/admin/login|/PROTECTED_PAGE|;s/^([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED_IP]/;p}' access.log
```,
res: read("outputs/e8_3.txt"))

= Part C: Labels and spacing

== Exercise 9: Adding incident labels

`i` inserts a line before the matched line, `a` appends one after it and `c` replaces it. The one-line `i text` form is a GNU extension.

#q([1. Heading before the first line of `auth.log`.],
```bash
sed '1i SECURITY AUTHENTICATION LOG' auth.log
```,
res: read("outputs/e9_1.txt"))

#q([2. Closing message after the last entry.],
```bash
sed '$a END OF SECURITY LOG' auth.log
```,
res: read("outputs/e9_2.txt"))

#q([3. `[WARNING]` before every failed login.],
```bash
sed '/Failed password/i [WARNING]' auth.log
```,
res: read("outputs/e9_3.txt"))

#q([4. `Review this event` after every invalid-user entry.],
```bash
sed '/Invalid user/a Review this event' auth.log
```,
res: read("outputs/e9_4.txt"))

#q([5. `[SUSPICIOUS WEB REQUEST]` before every 403 entry.],
```bash
sed '/ 403$/i [SUSPICIOUS WEB REQUEST]' access.log
```,
res: read("outputs/e9_5.txt"))

#q([6. `[REQUIRES INVESTIGATION]` after every 401 entry.],
```bash
sed '/ 401$/a [REQUIRES INVESTIGATION]' access.log
```,
res: read("outputs/e9_6.txt"))

#q([7. Replace every `Connection closed` entry with `[CONNECTION TERMINATED]`.],
```bash
sed '/Connection closed/c [CONNECTION TERMINATED]' auth.log
```,
res: read("outputs/e9_7.txt"))

#q([8. Replace every successful web request with `[NORMAL WEB REQUEST]`.],
```bash
sed '/ 200$/c [NORMAL WEB REQUEST]' access.log
```,
res: read("outputs/e9_8.txt"))

== Exercise 10: Separating log entries with G

`G` appends the hold space to the pattern space. The hold space starts empty, so the effect is a blank line after the entry.

#q([1. A blank line after every authentication event.],
```bash
sed G auth.log
```,
res: read("outputs/e10_1.txt"))

#q([2. A blank line after every failed login only.],
```bash
sed '/Failed password/G' auth.log
```,
res: read("outputs/e10_2.txt"))

#q([3. A blank line after every blocked web request.],
```bash
sed '/ 403$/G' access.log
```,
res: read("outputs/e10_3.txt"))

#q([4. A blank line after every second entry, starting with the first.],
```bash
sed '1~2G' auth.log
```,
res: read("outputs/e10_4.txt"))

= Part D: Saving output and combining commands

== Exercise 11: Writing events to files

`w file` writes the selected lines to a file. With `-n` nothing reaches the screen, so each result is checked with `cat`.

#q([1. Failed logins.],
```bash
sed -n '/Failed password/w failed_logins.txt' auth.log
cat failed_logins.txt
```,
res: read("outputs/e11_1.txt"))

#q([2. Successful logins.],
```bash
sed -n '/Accepted password/w successful_logins.txt' auth.log
cat successful_logins.txt
```,
res: read("outputs/e11_2.txt"))

#q([3. Invalid-user events.],
```bash
sed -n '/Invalid user/w invalid_users.txt' auth.log
cat invalid_users.txt
```,
res: read("outputs/e11_3.txt"))

#q([4. Web requests with status 401.],
```bash
sed -n '/ 401$/w unauthorized_requests.txt' access.log
cat unauthorized_requests.txt
```,
res: read("outputs/e11_4.txt"))

#q([5. Web requests with status 403.],
```bash
sed -n '/ 403$/w blocked_requests.txt' access.log
cat blocked_requests.txt
```,
res: read("outputs/e11_5.txt"))

#q([6. Every event involving `172.16.0.8`, from both logs. `sed` opens the output file once, so lines from the second input file are appended and not overwritten.],
```bash
sed -n '/172\.16\.0\.8/w suspicious_ip.txt' auth.log access.log
cat suspicious_ip.txt
```,
res: read("outputs/e11_6.txt"))

== Exercise 12: Combining operations

Several `-e` options run in order on each line.

#q([1. Label successful and failed logins.],
```bash
sed -e 's/Accepted password/[SUCCESSFUL LOGIN]/' -e 's/Failed password/[FAILED LOGIN]/' auth.log
```,
res: read("outputs/e12_1.txt"))

#q([2. Label 401 and 403 requests.],
```bash
sed -e 's/ 401$/ [UNAUTHORIZED]/' -e 's/ 403$/ [BLOCKED]/' access.log
```,
res: read("outputs/e12_2.txt"))

#q([3. Delete successful logins, then delete everything that is not a failed login, which leaves the failed logins.],
```bash
sed -e '/Accepted password/d' -e '/Failed password/!d' auth.log
```,
res: read("outputs/e12_3.txt"))

#q([4. Replace `root` and mask every IP address.],
```bash
sed -E -e 's/root/[PRIVILEGED_USER]/g' -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED_IP]/g' auth.log
```,
res: read("outputs/e12_4.txt"))

#q([5. Replace `GET` and `POST`.],
```bash
sed -e 's/GET/READ_REQUEST/' -e 's/POST/SUBMIT_REQUEST/' access.log
```,
res: read("outputs/e12_5.txt"))

= Part E: Scripts and configuration

== Exercise 13: A sed script file

`-f` reads the commands from a file. Inside a script file `i\` and `a\` take their text on the next line, and the file uses basic regular expressions, so the interval braces are escaped.

#q([Create `security_report.sed`.],
```bash
cat > security_report.sed << 'EOF'
1i\
SECURITY INCIDENT REPORT
s/Failed password/[FAILED LOGIN]/
s/Invalid user/[INVALID USER ATTEMPT]/
s/Accepted password/[SUCCESSFUL LOGIN]/
s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/[REDACTED_IP]/g
$a\
END OF INCIDENT REPORT
EOF
```)

#q([Execute it.],
```bash
sed -f security_report.sed auth.log
```,
res: read("outputs/e13_2.txt"))

#q([Save the output.],
```bash
sed -f security_report.sed auth.log > incident_report.txt
cat incident_report.txt
```,
res: read("outputs/e13_3.txt"))

== Exercise 14: Modifying a security configuration file

This edits a sample file only. Nothing on the system is configured.

#q([Create `security.conf` and take a backup.],
```bash
cat > security.conf << 'EOF'
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 6
FirewallStatus disabled
LogLevel INFO
GuestLogin enabled
EOF
cp security.conf security.conf.backup
ls security.conf*
```,
res: read("outputs/e14_1.txt"))

#q([Apply the five changes in place. `-i.bak` edits the file and keeps the previous version as `security.conf.bak`. The five expressions go into one command: run as five separate `-i.bak` commands, each would overwrite the `.bak` file left by the one before, and only the state before the last edit would survive.],
```bash
sed -i.bak \
  -e 's/PermitRootLogin yes/PermitRootLogin no/' \
  -e 's/MaxAuthTries 6/MaxAuthTries 3/' \
  -e 's/FirewallStatus disabled/FirewallStatus enabled/' \
  -e 's/LogLevel INFO/LogLevel VERBOSE/' \
  -e 's/GuestLogin enabled/GuestLogin disabled/' \
  security.conf
cat security.conf
```,
res: read("outputs/e14_2.txt"))

#q([Compare the edited file with the backups. `diff` prints nothing between the two copies of the original, and `<` marks the old lines.],
```bash
diff security.conf.backup security.conf.bak && echo "backup and .bak are identical"
diff security.conf.backup security.conf
```,
res: read("outputs/e14_3.txt"))

== Exercise 15: Security log analyser script

The script is saved as `security_log_analyser.sh` and made executable with `chmod +x`.

#q([Test with no argument.],
```bash
chmod +x security_log_analyser.sh
./security_log_analyser.sh
echo "exit status: $?"
```,
res: read("outputs/e15_1.txt"))

#q([Test with a file that does not exist.],
```bash
./security_log_analyser.sh missing.log
echo "exit status: $?"
```,
res: read("outputs/e15_2.txt"))

#q([Run it on `auth.log`. The report is written to `security_alert_report.txt` and then displayed.],
```bash
./security_log_analyser.sh auth.log
echo "exit status: $?"
```,
res: read("outputs/e15_3.txt"))

#q([The saved file matches what was displayed, and the input log is unchanged.],
```bash
wc -l security_alert_report.txt auth.log
```,
res: read("outputs/e15_4.txt"))

== Scripts used

#q([`security_report.sed`, run in Exercise 13.],
raw(read("security_report.sed").trim("\n"), block: true, lang: "sed"))

#q([`security_log_analyser.sh`, run in Exercise 15.],
raw(read("security_log_analyser.sh").trim("\n"), block: true, lang: "bash"))

= Result

`sed` handled each task as a short command applied line by line: `-n` with `p` to print, `d` to delete, `s` to substitute, `i`, `a` and `c` to insert, append and replace, `G` to space entries out and `w` to write them to files. Regular expression addresses selected the failed logins, invalid users and blocked requests, and `!` inverted the selection when the interesting lines were the ones that did not match.

In the logs, `10.0.0.25` produced two failed root logins, a closed connection and both attempts on `/admin/login`. `172.16.0.8` was behind the invalid-user attempt, a failed admin login, the SQL injection and the script injection. `10.0.0.30` tried root and requested `/../../etc/passwd`. The same patterns were then reused in a `-f` script file, an in-place edit of `security.conf` with a `.bak` copy, and `security_log_analyser.sh`, which checks its argument, extracts the failed-login and invalid-user lines, masks the addresses and saves a labelled report.
