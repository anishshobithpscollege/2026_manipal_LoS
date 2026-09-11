#import "/template/lib.typ": *
#import "@preview/codly:1.3.0" as codly

#show: assignment.with(
  title: "Grep, Regular Expressions, Filters and Redirection",
  number: "Assignment 04",
  kind: "Lab",
  date: datetime(year: 2026, month: 9, day: 11),
)

#let out(body) = codly.local(number-format: none)[#raw(body.trim("\n"), block: true)]
#let q(desc, cmd, res: none) = block(above: 0.7em, below: 0.4em, breakable: true, {
  desc
  v(2pt)
  codly.local(number-format: none)[#cmd]
  if res != none { out(res) }
})

= Aim

Use `grep`, extended regular expressions (`grep -E`), the filter utilities
`sort`, `uniq`, `head`, `tail`, `cut`, `tr` and `sed`, and shell
redirection to analyse a security log. Every command in this record was run
from inside `04-grep-regex-direction/` on a Linux shell with GNU `grep` 3.12,
and the output shown is the output the command produced.

== Files in the working directory

`security_log.txt` holds 91 lines. The first 87 lines carry a bracketed
timestamp of the form `[YYYY-MM-DD HH:MM:SS]` followed by a severity word and a
message. The last four lines have no timestamp, which makes them useful for the
anchor exercises in Part C.

`web_access.log` and `firewall.log` are two short companion logs, five lines
each, written for the one question in Part A that needs more than a single file
to search.

= Part A: Basic grep and filtering

#q([1. Lines containing `failed`. The log writes the word with a capital F, so the lowercase pattern matches nothing and `grep` exits with status 1.],
```bash
grep "failed" security_log.txt
```,
res: read("outputs/a1.txt"))

#q([2. The same word ignoring case.],
```bash
grep -i "failed" security_log.txt
```,
res: read("outputs/a2.txt"))

#q([3. Lines containing either `Failed` or `Denied`. The alternation returns 10 lines, all of them `Failed`, because the log spells the second word `denied` in lowercase.],
```bash
grep -E "Failed|Denied" security_log.txt
grep -cE "Failed|Denied" security_log.txt
```,
res: read("outputs/a3.txt"))

#q([Adding `-i` picks up the three `denied` lines as well.],
```bash
grep -icE "failed|denied" security_log.txt
```,
res: read("outputs/a4.txt"))

#q([The three extra lines are the ones the case-sensitive pattern missed.],
```bash
grep -iE "failed|denied" security_log.txt | grep -v "Failed"
```,
res: read("outputs/a5.txt"))

#q([4. Lines that do not contain `INFO`. There are 66 of them, so the first 8 are shown.],
```bash
grep -v "INFO" security_log.txt | head -8
grep -cv "INFO" security_log.txt
```,
res: read("outputs/a6.txt"))

#q([5. The exact word `root`. `-w` requires a non-word character on both sides, so a longer word such as `rooted` would not match.],
```bash
grep -w "root" security_log.txt
```,
res: read("outputs/a7.txt"))

#q([6. Occurrences of `attack` with line numbers. The only hit is inside the email address `attacker123@phishing-example.com`, so `-n` points straight at the line to read.],
```bash
grep -n "attack" security_log.txt
```,
res: read("outputs/a8.txt"))

#q([7. Count of lines containing `ERROR`.],
```bash
grep -c "ERROR" security_log.txt
```,
res: read("outputs/a9.txt"))

#q([8. Filenames whose contents contain `malware`. `-l` prints the name once and stops reading that file.],
```bash
grep -l "malware" security_log.txt web_access.log firewall.log
```,
res: read("outputs/a10.txt"))

#q([9. First five lines containing `Suspicious`.],
```bash
grep "Suspicious" security_log.txt | head -5
```,
res: read("outputs/a11.txt"))

#q([10. Last five failed-login entries.],
```bash
grep "Failed login" security_log.txt | tail -5
```,
res: read("outputs/a12.txt"))

= Part B: Regular expression extraction

`grep -o` prints each match on its own line instead of the whole line, which is
how it extracts values from the log. Every pattern in this part uses
`-E`, so `{n,m}`, `+`, `?` and grouping work without backslashes.

#q([1. All IPv4 addresses. There are 35 matches spread over 33 lines, so the first 12 are shown.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | head -12
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | wc -l
```,
res: read("outputs/b1.txt"))

Counting matches needs `wc -l` rather than `grep -c`. `grep -c` reports 33
because it counts matching lines, and two lines each hold two addresses.

#q([2. Addresses in the 10.0.0.0 private range. `\b` anchors both ends so that `110.1.2.3` or `10.1.2.30` cannot match a shorter address by accident.],
```bash
grep -oE "\b10(\.[0-9]{1,3}){3}\b" security_log.txt
```,
res: read("outputs/b2.txt"))

#q([3. Addresses in the 192.168.0.0 range.],
```bash
grep -oE "\b192\.168(\.[0-9]{1,3}){2}\b" security_log.txt
```,
res: read("outputs/b3.txt"))

#q([4. Email addresses.],
```bash
grep -oE "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" security_log.txt
```,
res: read("outputs/b4.txt"))

#q([5. Only the addresses whose domain ends in `.com`.],
```bash
grep -oE "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.com\b" security_log.txt
```,
res: read("outputs/b5.txt"))

#q([6. Addresses whose username part holds at least one digit. The pattern places `[0-9]` between two runs of optional username characters, so the digit can sit anywhere before the `@`.],
```bash
grep -oE "[A-Za-z0-9._%+-]*[0-9][A-Za-z0-9._%+-]*@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" security_log.txt
```,
res: read("outputs/b6.txt"))

#q([7. URLs starting with `http://` or `https://`. `[^ ]+` runs to the first space, which is where a URL ends in this log.],
```bash
grep -oE "https?://[^ ]+" security_log.txt
```,
res: read("outputs/b7.txt"))

#q([8. HTTPS only. Dropping the `?` makes the `s` mandatory.],
```bash
grep -oE "https://[^ ]+" security_log.txt
```,
res: read("outputs/b8.txt"))

#q([9. URLs ending in `.php`.],
```bash
grep -oE "https?://[^ ]+\.php" security_log.txt
```,
res: read("outputs/b9.txt"))

#q([10. CVE identifiers. The sequence number is written with four to six digits in this log, so the pattern accepts `{4,7}` rather than a fixed four.],
```bash
grep -oE "CVE-[0-9]{4}-[0-9]{4,7}" security_log.txt
```,
res: read("outputs/b10.txt"))

#q([11. Only the 2025 identifiers.],
```bash
grep -oE "CVE-2025-[0-9]{4,7}" security_log.txt
```,
res: read("outputs/b11.txt"))

#q([12. MD5 hashes, 32 hex characters.],
```bash
grep -oE "\b[a-fA-F0-9]{32}\b" security_log.txt
```,
res: read("outputs/b12.txt"))

#q([13. SHA-1 hashes, 40 hex characters.],
```bash
grep -oE "\b[a-fA-F0-9]{40}\b" security_log.txt
```,
res: read("outputs/b13.txt"))

#q([14. SHA-256 hashes, 64 hex characters.],
```bash
grep -oE "\b[a-fA-F0-9]{64}\b" security_log.txt
```,
res: read("outputs/b14.txt"))

The `\b` on both sides matters here. Without it the 32-character pattern would
also match the first 32 characters of the SHA-1 and SHA-256 hashes and report
three hashes that do not exist.

#q([15. Timestamps in `YYYY-MM-DD HH:MM:SS` form. 87 of the 91 lines carry one.],
```bash
grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" security_log.txt | head -5
grep -coE "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" security_log.txt
```,
res: read("outputs/b15.txt"))

= Part C: Anchors and regex patterns

#q([1. Lines beginning with a timestamp. The timestamp sits inside square brackets, so `^` is followed by an escaped `\[`.],
```bash
grep -E "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]" security_log.txt | head -3
grep -cE "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]" security_log.txt
```,
res: read("outputs/c1.txt"))

#q([2. Lines beginning with `Suspicious`. Only the untimestamped tail of the file qualifies, because every other suspicious entry starts with `[`.],
```bash
grep "^Suspicious" security_log.txt
```,
res: read("outputs/c2.txt"))

#q([3. Lines ending in a digit. 47 lines end with a port, a status code or an address octet.],
```bash
grep -E "[0-9]$" security_log.txt | head -5
grep -cE "[0-9]$" security_log.txt
```,
res: read("outputs/c3.txt"))

#q([4. Lines beginning with `ERROR` or `WARNING`. Again only the tail matches, since a severity word that follows a timestamp is not at the start of the line.],
```bash
grep -E "^(ERROR|WARNING)" security_log.txt
```,
res: read("outputs/c4.txt"))

#q([5. Lines whose first character is a digit. Every line starts with either `[` or a capital letter, so nothing matches and the exit status is 1.],
```bash
grep -E "^[0-9]" security_log.txt
```,
res: read("outputs/c5.txt"))

#q([6. Lines ending in `.exe`.],
```bash
grep "\.exe$" security_log.txt
```,
res: read("outputs/c6.txt"))

#q([7. Lines holding a filename that ends in `.exe`, `.sh` or `.pdf`, anywhere on the line. 19 lines match, so the first 6 are shown.],
```bash
grep -E "\.(exe|sh|pdf)\b" security_log.txt | head -6
grep -cE "\.(exe|sh|pdf)\b" security_log.txt
```,
res: read("outputs/c7.txt"))

#q([8. The exact word `root`, excluding longer words such as `rooted`. Both counts agree at 6 because this log contains no such longer word, so `-w` changes nothing here. It is still the correct pattern to write: on a log that did contain `rooted`, the plain search would over-report.],
```bash
grep -cw "root" security_log.txt
grep -c "root" security_log.txt
```,
res: read("outputs/c8.txt"))

#q([9. Blank lines. `^$` matches a line with nothing between start and end. This log has none.],
```bash
grep -n "^$" security_log.txt
grep -c "^$" security_log.txt
```,
res: read("outputs/c9.txt"))

#q([10. Non-blank lines, which is all 91 of them.],
```bash
grep -cv "^$" security_log.txt
```,
res: read("outputs/c10.txt"))

= Part D: Linux filters and pipelines

The pattern in this part is always the same. `grep -o` pulls the field out of
the line, `cut` or `sed` trims it down to the value, then `sort` and `uniq`
turn the stream into a summary. `uniq` only collapses adjacent duplicates, so
`sort` has to come first.

#q([1. IPv4 addresses, sorted, with duplicates removed.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | sort | uniq
```,
res: read("outputs/d1.txt"))

#q([2. Count of unique addresses. `sort -u` does the same job as `sort | uniq` in one process.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | sort -u | wc -l
```,
res: read("outputs/d2.txt"))

#q([3. All addresses in sorted order, duplicates kept. 35 lines, first 12 shown.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | sort | head -12
```,
res: read("outputs/d3.txt"))

Plain `sort` compares text, which is why `1.1.1.1` sorts above `10.1.2.3` and
`8.8.8.8` lands at the bottom. `sort -V` compares the octets as numbers and
puts `8.8.8.8` in second place.

#q([4. Addresses that appear more than once. `uniq -d` prints only the values that had a duplicate.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | sort | uniq -d
```,
res: read("outputs/d4.txt"))

#q([5. The most frequent address. `uniq -c` prefixes each value with its count, `sort -nr` orders by that count, and `head -1` keeps the top row.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | sort | uniq -c | sort -nr | head -1
```,
res: read("outputs/d5.txt"))

#q([6. Unique usernames from the authentication entries. The first `grep` selects login records, the second pulls the `for user NAME` phrase out of them, and `cut` keeps the third field.],
```bash
grep -E "(Failed|Successful) login" security_log.txt \
  | grep -oE "for user [a-z]+" | cut -d' ' -f3 | sort -u
```,
res: read("outputs/d6.txt"))

#q([7. Authentication attempts per username.],
```bash
grep -E "(Failed|Successful) login" security_log.txt \
  | grep -oE "for user [a-z]+" | cut -d' ' -f3 | sort | uniq -c | sort -nr
```,
res: read("outputs/d7.txt"))

#q([8. HTTP status codes and how often each appears.],
```bash
grep -oE "status [0-9]{3}" security_log.txt | cut -d' ' -f2 | sort | uniq -c | sort -nr
```,
res: read("outputs/d8.txt"))

#q([9. Five most frequent addresses.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | sort | uniq -c | sort -nr | head -5
```,
res: read("outputs/d9.txt"))

#q([10. Three most frequent usernames.],
```bash
grep -E "(Failed|Successful) login" security_log.txt \
  | grep -oE "for user [a-z]+" | cut -d' ' -f3 | sort | uniq -c | sort -nr | head -3
```,
res: read("outputs/d10.txt"))

#q([11. Destination ports in numerical order. `sort -n` is needed here, because plain `sort` would place `2222` before `443`.],
```bash
grep -oE "port [0-9]+" security_log.txt | cut -d' ' -f2 | sort -n
```,
res: read("outputs/d11.txt"))

#q([12. The same list with duplicates removed.],
```bash
grep -oE "port [0-9]+" security_log.txt | cut -d' ' -f2 | sort -n | uniq
```,
res: read("outputs/d12.txt"))

#q([13. Count of unique ports.],
```bash
grep -oE "port [0-9]+" security_log.txt | cut -d' ' -f2 | sort -u | wc -l
```,
res: read("outputs/d13.txt"))

#q([14. File extensions and their frequency. The extensions are listed explicitly because a general pattern such as `\.[a-z]+` would also capture the `.com`, `.ru` and `.in` at the end of every domain name.],
```bash
grep -oE "\.(exe|sh|pdf|php|html|dat)\b" security_log.txt | sort | uniq -c | sort -nr
```,
res: read("outputs/d14.txt"))

#q([15. Five most frequent domains, taken from the host part of every URL. `[^/ ]+` stops at the first slash or space, which is exactly where the hostname ends.],
```bash
grep -oE "https?://[^/ ]+" security_log.txt | sed 's|https\?://||' \
  | sort | uniq -c | sort -nr | head -5
```,
res: read("outputs/d15.txt"))

Only two hosts are requested more than once, so the ranking below the top two
is decided by the reverse alphabetical order that `sort -nr` falls back on when
the counts tie.

= Part E: Combining grep conditions

Two conditions on the same line are handled by piping one `grep` into another.
The first narrows the file, the second filters what is left.

#q([1. Lines holding both an IP address and the word `Failed`.],
```bash
grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | grep "Failed"
```,
res: read("outputs/e1.txt"))

#q([2. Lines holding both `root` and `Failed`. This drops the crontab line, which mentions `root` without being a login failure.],
```bash
grep -w "root" security_log.txt | grep "Failed"
```,
res: read("outputs/e2.txt"))

#q([3. Lines holding either `download` or `upload`. This is an OR, so it stays in one `grep -E` rather than a pipe.],
```bash
grep -E "download|upload" security_log.txt
```,
res: read("outputs/e3.txt"))

#q([4. Suspicious entries that reference an `.exe` or `.sh` file.],
```bash
grep "Suspicious" security_log.txt | grep -E "\.(exe|sh)\b"
```,
res: read("outputs/e4.txt"))

#q([5. Lines holding a CVE identifier and an IP address. Two of the six CVE lines name the source address.],
```bash
grep -E "CVE-[0-9]{4}-[0-9]+" security_log.txt | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}"
```,
res: read("outputs/e5.txt"))

#q([6. Lines holding both a filename and a hash value. These are the records that tie a file to something a threat feed can be checked against.],
```bash
grep -E "[A-Za-z0-9_]+\.(exe|sh|pdf)\b" security_log.txt | grep -E "\b[a-fA-F0-9]{32,64}\b"
```,
res: read("outputs/e6.txt"))

#q([7. An IP address followed by a port, written either as `host:port` or as `address port N`. 18 lines match, first 6 shown.],
```bash
grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]+| port [0-9]+)" security_log.txt | head -6
grep -cE "([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]+| port [0-9]+)" security_log.txt
```,
res: read("outputs/e7.txt"))

#q([8. HTTP requests carrying both a URL and status 404.],
```bash
grep -E "https?://" security_log.txt | grep "status 404"
```,
res: read("outputs/e8.txt"))

#q([9. Authentication failures other than those from the loopback address. All 10 failures survive the filter, since none of them came from `127.0.0.1`.],
```bash
grep "Failed login" security_log.txt | grep -v "127\.0\.0\.1" | wc -l
```,
res: read("outputs/e9.txt"))

#q([10. Attack-related entries with informational messages removed. 30 lines match, first 6 shown.],
```bash
grep -iE "attack|exploit|brute|suspicious" security_log.txt | grep -v "INFO" | head -6
```,
res: read("outputs/e10.txt"))

= Part F: Negative matching

`grep -v` inverts the selection. Placed after a `grep -o` it filters the
extracted values rather than the log lines, which is how the first question
here is answered.

#q([1. All IPv4 addresses except the loopback range. This log holds no `127.x.x.x` address, so the filter removes nothing and the 13 unique addresses all remain.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt | grep -v "^127\." | sort -u
```,
res: read("outputs/f1.txt"))

#q([2. Everything except successful logins. One line is removed, leaving 90.],
```bash
grep -v "Successful login" security_log.txt | wc -l
```,
res: read("outputs/f2.txt"))

#q([3. Entries that carry none of `INFO`, `DEBUG` or `SUCCESS`. 64 lines remain, first 6 shown.],
```bash
grep -vE "INFO|DEBUG|SUCCESS" security_log.txt | head -6
grep -cvE "INFO|DEBUG|SUCCESS" security_log.txt
```,
res: read("outputs/f3.txt"))

#q([4. HTTP requests whose status code is anything other than 200. The first `grep` keeps only lines that report a status at all, so lines without one are not counted as failures.],
```bash
grep "status " security_log.txt | grep -v "status 200"
```,
res: read("outputs/f4.txt"))

#q([5. Suspicious traffic that does not involve the internal 192.168 network. No suspicious entry names a 192.168 address, so all 24 lines survive the filter. The first 6 are shown.],
```bash
grep "Suspicious" security_log.txt | grep -v "192\.168\." | head -6
grep "Suspicious" security_log.txt | grep -vc "192\.168\."
```,
res: read("outputs/f5.txt"))

#q([6. Email addresses outside the organisation's own `example.com` domain. The `$` anchor keeps `attacker123@phishing-example.com` in the list, because that address ends in `phishing-example.com` and not `@example.com`.],
```bash
grep -oE "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" security_log.txt \
  | grep -v "@example\.com$"
```,
res: read("outputs/f6.txt"))

= Part G: Redirection

`>` writes standard output to a file and truncates whatever was there. `>>`
appends instead. `2>` redirects standard error, which travels on a separate
channel and would otherwise reach the terminal even when `>` is in use.

#q([1. IPv4 addresses into `ips.txt`.],
```bash
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" security_log.txt > ips.txt
wc -l < ips.txt
```,
res: read("outputs/g1.txt"))

#q([2. Email addresses into `emails.txt`.],
```bash
grep -oE "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" security_log.txt > emails.txt
cat emails.txt
```,
res: read("outputs/g2.txt"))

#q([3. URLs into `urls.txt`.],
```bash
grep -oE "https?://[^ ]+" security_log.txt > urls.txt
wc -l < urls.txt
```,
res: read("outputs/g3.txt"))

#q([4. Hashes of all three lengths into `hashes.txt`. The alternation keeps the `\b` anchors on each branch so that a 64-character hash is reported once as itself rather than three times at three different lengths.],
```bash
grep -oE "\b[a-fA-F0-9]{32}\b|\b[a-fA-F0-9]{40}\b|\b[a-fA-F0-9]{64}\b" \
  security_log.txt > hashes.txt
cat hashes.txt
```,
res: read("outputs/g4.txt"))

#q([5. Failed-login entries into `failed_login.txt`.],
```bash
grep "Failed login" security_log.txt > failed_login.txt
wc -l < failed_login.txt
```,
res: read("outputs/g5.txt"))

#q([6. Suspicious entries appended to `incident_report.txt`. `>>` is the right operator here because an incident report grows across several runs, and `>` would discard everything written before.],
```bash
grep "Suspicious" security_log.txt >> incident_report.txt
wc -l < incident_report.txt
```,
res: read("outputs/g6.txt"))

#q([7. Unique addresses into `unique_ips.txt`.],
```bash
sort -u ips.txt > unique_ips.txt
cat unique_ips.txt
```,
res: read("outputs/g7.txt"))

#q([8. Frequency statistics into `ip_frequency.txt`.],
```bash
sort ips.txt | uniq -c | sort -nr > ip_frequency.txt
cat ip_frequency.txt
```,
res: read("outputs/g8.txt"))

#q([9. Output to `results.txt` and errors to `errors.txt`. A second filename that does not exist is supplied so that `grep` has an error to report. The matches still land in `results.txt` and the terminal stays clean.],
```bash
grep "Failed login" security_log.txt no_such_file.log > results.txt 2> errors.txt
cat errors.txt
wc -l < results.txt
```,
res: read("outputs/g9.txt"))

#q([10. Domains from the `Domain accessed` entries, lowercased, sorted and deduplicated, into `domains.txt`. The domain is the last field on those lines, so `sed 's/.* //'` keeps the last field.],
```bash
grep "Domain accessed" security_log.txt | sed 's/.* //' \
  | tr 'A-Z' 'a-z' | sort -u > domains.txt
cat domains.txt
```,
res: read("outputs/g10.txt"))

#q([11. Unique source addresses of failed logins into `failed_login_ips.txt`. Anchoring on the word `from` keeps the source address and discards the port number that follows it.],
```bash
grep "Failed login" security_log.txt \
  | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" | cut -d' ' -f2 \
  | sort -u > failed_login_ips.txt
cat failed_login_ips.txt
```,
res: read("outputs/g11.txt"))

Five hosts produced all 10 failures. `198.51.100.77` and `203.0.113.45` account
for three each, and both also appear elsewhere in the log as the source of
denied connections and command-and-control traffic.

= Part H: Combining filters with redirection

`tr` translates one set of characters into another and is the shortest way to
change case or delete a character class. `cut -d= -f2` splits a field on `=`
and keeps the right-hand side. Both go at the end of a `grep -o` pipeline.

#q([1. Failed-login usernames into `failed_users.txt`.],
```bash
grep "Failed login" security_log.txt | grep -oE "for user [a-z]+" \
  | cut -d' ' -f3 | sort -u > failed_users.txt
cat failed_users.txt
```,
res: read("outputs/h1.txt"))

#q([2. Domains in lowercase into `domains.txt`. This is the same file written in Part G question 10, rebuilt here as a single pipeline.],
```bash
grep "Domain accessed" security_log.txt | sed 's/.* //' \
  | tr 'A-Z' 'a-z' | sort -u > domains.txt
cat domains.txt
```,
res: read("outputs/h2.txt"))

#q([3. MD5 hashes in uppercase into `md5_hashes.txt`. Anchoring on the `MD5=` label keeps the SHA-1 and SHA-256 values out of the file.],
```bash
grep -oE "MD5=[a-fA-F0-9]{32}" security_log.txt | cut -d= -f2 \
  | tr 'a-z' 'A-Z' > md5_hashes.txt
cat md5_hashes.txt
```,
res: read("outputs/h3.txt"))

#q([4. Source addresses of failed logins, sorted and deduplicated, into `failed_ips.txt`.],
```bash
grep "Failed login" security_log.txt \
  | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" | cut -d' ' -f2 \
  | sort | uniq > failed_ips.txt
cat failed_ips.txt
```,
res: read("outputs/h4.txt"))

#q([5. `clean_log.txt`, the log with every square bracket removed. `tr -d` deletes each character in the set rather than translating it, which strips the brackets and leaves the timestamp in place.],
```bash
tr -d '[]' < security_log.txt > clean_log.txt
head -3 clean_log.txt
```,
res: read("outputs/h5.txt"))

#q([6. `normalized_log.txt`, the whole file folded to lowercase.],
```bash
tr 'A-Z' 'a-z' < security_log.txt > normalized_log.txt
head -3 normalized_log.txt
```,
res: read("outputs/h6.txt"))

#q([7. `unique_domains.txt`, built from both sources of domain names in the log. The braces group two commands so that a single `tr` and `sort -u` runs over their combined output.],
```bash
{ grep -oE "https?://[^/ ]+" security_log.txt | sed 's|https\?://||' ;
  grep "Domain accessed" security_log.txt | sed 's/.* //' ; } \
  | tr 'A-Z' 'a-z' | sort -u > unique_domains.txt
cat unique_domains.txt
```,
res: read("outputs/h7.txt"))

#q([8. Usernames from failed logins, in the order they occur. The repetition is the finding: `root` three times in a row at 08:12, then twice more at 08:42.],
```bash
grep "Failed login" security_log.txt | grep -oE "for user [a-z]+" | cut -d' ' -f3
```,
res: read("outputs/h8.txt"))

#q([9. Source addresses of failed logins in sorted order.],
```bash
grep "Failed login" security_log.txt \
  | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" | cut -d' ' -f2 | sort
```,
res: read("outputs/h9.txt"))

#q([10. Count of distinct addresses behind those failures.],
```bash
grep "Failed login" security_log.txt \
  | grep -oE "from ([0-9]{1,3}\.){3}[0-9]{1,3}" | cut -d' ' -f2 | sort -u | wc -l
```,
res: read("outputs/h10.txt"))

#q([11. Failed-login usernames in uppercase with duplicates removed.],
```bash
grep "Failed login" security_log.txt | grep -oE "for user [a-z]+" \
  | cut -d' ' -f3 | tr 'a-z' 'A-Z' | sort -u
```,
res: read("outputs/h11.txt"))

#q([12. Domain names from the `Domain accessed` lines in lowercase, in file order.],
```bash
grep "Domain accessed" security_log.txt | sed 's/.* //' | tr 'A-Z' 'a-z'
```,
res: read("outputs/h12.txt"))

#q([13. MD5 values from the `MD5=` lines, with the hex letters in uppercase.],
```bash
grep -oE "MD5=[a-fA-F0-9]{32}" security_log.txt | cut -d= -f2 | tr 'a-z' 'A-Z'
```,
res: read("outputs/h13.txt"))

#q([14. User-agent strings in lowercase. `sed` removes the `User-Agent: ` label, leaving only the value.],
```bash
grep -oE "User-Agent: .*" security_log.txt | sed 's/User-Agent: //' | tr 'A-Z' 'a-z'
```,
res: read("outputs/h14.txt"))

`evilscanner` and `python-requests` are the two worth noting. Neither is a
browser, and the first names itself in the request.

#q([15. CVE identifiers in lowercase.],
```bash
grep -oE "CVE-[0-9]{4}-[0-9]{4,7}" security_log.txt | tr 'A-Z' 'a-z'
```,
res: read("outputs/h15.txt"))

#q([16. Executable filenames in uppercase, deduplicated. `[A-Za-z0-9_-]+\.exe` captures the filename without the directory path in front of it.],
```bash
grep -oE "[A-Za-z0-9_-]+\.exe" security_log.txt | sort -u | tr 'a-z' 'A-Z'
```,
res: read("outputs/h16.txt"))

#q([17. Domains from the `Domain accessed` entries in uppercase, sorted and deduplicated.],
```bash
grep "Domain accessed" security_log.txt | sed 's/.* //' | tr 'a-z' 'A-Z' | sort -u
```,
res: read("outputs/h17.txt"))

== Files produced

Running Parts G and H leaves 18 generated files in the working directory
alongside the three input logs.

#q([Listing after both parts have been run.],
```bash
ls -1
```,
res: read("outputs/h18.txt"))

= Result

`grep -o` with an extended regular expression turned each log line into a
stream of single values, and `sort`, `uniq`, `tr` and `cut` reduced those
streams to counts and unique lists. Redirection saved each result to a named
file, and `2>` kept the one error message out of the result file.

The log itself shows a short intrusion. `198.51.100.77` and `203.0.113.45`
between them account for 6 of the 10 failed logins, five of which target
`root`. The same two addresses appear as the source of denied connections, a
403 response and traffic to `evilc2.ddns.net:9001`. The log records five
executables, six file hashes and five CVE references, three of which are
dated 2025. The files `ip_frequency.txt`, `failed_login_ips.txt` and
`unique_domains.txt` carry those findings in a form that can be handed to
another tool.
