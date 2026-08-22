#import "/template/lib.typ": *

// One solved exercise: the task, then the command shown in a code block.
#let solved(desc, cmd) = block(above: 0.9em, below: 0.5em, breakable: true, {
  desc
  v(3pt)
  raw(cmd, lang: "bash", block: true)
})

#let solvedshot(desc, path) = block(above: 0.9em, below: 0.5em, breakable: false, {
  desc
  v(3pt)
  layout(sz => {
    let img = image(path, width: sz.width)
    if measure(img).height > 20cm { align(center, image(path, height: 20cm)) } else { img }
  })
})

= Globbing

Globbing lets the shell match filenames with patterns such as `*`, `?`, and
`[ ]`, so one pattern selects a group of files instead of each name typed out.
Brace expansion is a separate feature: the shell rewrites the braces into a list
before the command runs, so a single `touch` line creates many files.

*Brace expansion.* One line can create many files, because the shell expands the
braces before `touch` runs. Set up a practice directory and try it:

```bash
mkdir globbing-practice && cd globbing-practice
touch {1..5}.png            # 1.png 2.png 3.png 4.png 5.png
touch file{1..3}.txt        # file1.txt file2.txt file3.txt
touch img{01..10}.jpg       # zero-padded: img01.jpg … img10.jpg
touch report{A..C}.md       # reportA.md reportB.md reportC.md
```

#figure(
  image("assets/globbing-setup.png", width: 100%),
  caption: [Creating practice files with brace expansion],
)

```bash
touch index.html login.html admin.htm report.txt file123
touch user{1.txt,2.log}     # user1.txt user2.log
touch backup{1.html,2.txt}  # backup1.html backup2.txt
```

Extended globbing needs `shopt -s extglob` enabled first.

#solvedshot([1. List all files ending in `.html`.], "assets/glob-01.png")

#solvedshot([2. List all files other than `.html` files (extended globbing).], "assets/glob-02.png")

#solvedshot([3. List filenames containing at least one numeric digit.], "assets/glob-03.png")

#solvedshot([4. List files whose names begin with `user` followed by a single digit.], "assets/glob-04.png")

#solvedshot([5. List files ending in either `.txt` or `.log` using a single extended glob pattern.], "assets/glob-05.png")

#solvedshot([6. List files that do not end in `.txt` or `.log`.], "assets/glob-06.png")

#solvedshot([7. List files beginning with either `access` or `error` (extended globbing).], "assets/glob-07.png")

#solved([8. List `.html` files whose filenames contain a numeric digit.], "ls *[0-9]*.html")

= Extended Globbing

Extended globbing adds pattern operators: `?(...)` zero or one, `*(...)` zero or
more, `+(...)` one or more, `@(...)` exactly one, and `!(...)` anything except.
Turn them on first with `shopt -s extglob`.

*Set A.* A directory contains these files:
`access.log`, `error.log`, `auth.log`, `auth.log.1`, `auth.log.2`, `system.log`, `notes.txt`

#solvedshot([1. Select only `access.log`, `error.log` and `auth.log`.], "assets/extglob-01.png")

#solvedshot([2. Select all files except `notes.txt`.], "assets/extglob-02.png")

#solvedshot([3. Select files named either `auth.log.1` or `auth.log.2` using pattern matching.], "assets/extglob-03.png")

*Set B.* A directory contains these files:
`malware1.log`, `malware2.log`, `malwareA.log`, `malware_report.txt`, `normal.log`

#solvedshot([4. Select `.log` files whose names start with `malware` and contain a numeric character.], "assets/extglob-04.png")

*Set C.* A directory contains these files:
`failed_login.log`, `successful_login.log`, `login_backup.log`, `login.txt`, `firewall.log`

#solvedshot([5. Select `.log` files containing either `failed_login` or `successful_login`.], "assets/extglob-05.png")

#solvedshot([6. List all `.log` files except `firewall.log`.], "assets/extglob-06.png")

= Filters

`head` prints the first lines of a file, `tail` prints the last lines, and `wc`
counts lines, words, and bytes. A pipe feeds the output of one filter into the
next. The four sample logs are provided with the assignment: `login.log` (50
lines), `access.log` (80), `security.log` (120), and `incident.log` (500).

== `head`: first lines

#solvedshot([1. Display the first 10 entries of `login.log`.], "assets/fil-head-1.png")

#solvedshot([2. Display the first 5 entries of `access.log`.], "assets/fil-head-2.png")

#solvedshot([3. Display the first 15 security events from `security.log`.], "assets/fil-head-3.png")

#solvedshot([4. Display the first 20 events recorded in `incident.log`.], "assets/fil-head-4.png")

#solvedshot([5. Display only the first entry in `login.log`.], "assets/fil-head-5.png")

#solvedshot([6. Display the first 25 web requests recorded in `access.log`.], "assets/fil-head-6.png")

== `tail`, reading to end of file, and line counts

#solvedshot([1. Display the last 10 entries of `login.log`.], "assets/fil-tail-1.png")

#solvedshot([2. Display the last 5 entries of `access.log`.], "assets/fil-tail-2.png")

#solvedshot([3. Display the 20 most recent security events from `security.log`.], "assets/fil-tail-3.png")

#solvedshot([4. Display the 25 most recent events from `incident.log`.], "assets/fil-tail-4.png")

#solvedshot([5. Display only the last entry in `security.log`.], "assets/fil-tail-5.png")

#solvedshot([6. Display the last 50 events recorded in `incident.log`.], "assets/fil-tail-6.png")

#solvedshot([7. Display the contents of `login.log` starting from line 41 until the end.], "assets/fil-tail-7.png")

#solved([8. Display the contents of `security.log` starting from line 101 until the end.], "tail -n +101 security.log")

#solved([9. Find the total number of lines in `login.log`.], "wc -l login.log")

#solved([10. Find the total number of lines in `access.log`.], "wc -l access.log")

== `wc`: counting lines, words, bytes

#solved([1. Find the total number of security events in `security.log`.], "wc -l security.log")

#solved([2. Determine the total number of events recorded in `incident.log`.], "wc -l incident.log")

#solved([3. Count the number of words in `login.log`.], "wc -w login.log")

#solved([4. Count the number of bytes in `security.log`.], "wc -c security.log")

#solved([5. Display the line, word, and byte counts of `access.log`.], "wc access.log")

#solved([6. Find the line counts of all four `.log` files using a single `wc` command.], "wc -l login.log access.log security.log incident.log")

== Pipelines: `head` and `tail`

#solved([1. First 20 entries of `login.log`, then only the last 5 of those.], "head -n 20 login.log | tail -n 5")

#solved([2. Last 20 entries of `login.log`, then only the first 5 of those.], "tail -n 20 login.log | head -n 5")

#solved([3. First 30 entries of `access.log`, then only the last 10 of that output.], "head -n 30 access.log | tail -n 10")

#solved([4. Last 30 entries of `access.log`, then only the first 10.], "tail -n 30 access.log | head -n 10")

#solved([5. First 50 events from `security.log`, then the last 10 of those 50.], "head -n 50 security.log | tail -n 10")

#solved([6. Last 50 events from `security.log`, then the first 10 of those 50.], "tail -n 50 security.log | head -n 10")

== Displaying line ranges

A range of lines from line _m_ to line _n_ is extracted by piping `head` into
`tail`: `head` keeps the first _n_ lines, and `tail` then keeps the last
_(n - m + 1)_ of those.

#solved([1. Display entries from line 11 to line 20 of `login.log`.], "head -n 20 login.log | tail -n 10")

#solved([2. Display entries from line 21 to line 30 of `login.log`.], "head -n 30 login.log | tail -n 10")

#solved([3. Display entries from line 11 to line 20 of `access.log`.], "head -n 20 access.log | tail -n 10")

#solved([4. Display entries from line 31 to line 40 of `access.log`.], "head -n 40 access.log | tail -n 10")

#solved([5. Display security events from line 21 to line 30 of `security.log`.], "head -n 30 security.log | tail -n 10")

#solved([6. Display security events from line 51 to line 60 of `security.log`.], "head -n 60 security.log | tail -n 10")

#solved([7. Display incident events from line 101 to line 110 of `incident.log`.], "head -n 110 incident.log | tail -n 10")

#solved([8. Display incident events from line 201 to line 220 of `incident.log`.], "head -n 220 incident.log | tail -n 20")

#solved([9. Display incident events from line 491 to line 500.], "tail -n 10 incident.log")

== Pipelines with `wc`

#solved([1. Take the first 20 entries of `login.log` and count how many lines are displayed.], "head -n 20 login.log | wc -l")

#solved([2. Take the last 15 entries of `access.log` and count how many lines are displayed.], "tail -n 15 access.log | wc -l")

#solved([3. Take the first 50 entries of `security.log` and count the number of words.], "head -n 50 security.log | wc -w")

#solved([4. Take the last 25 entries of `security.log` and count the number of lines.], "tail -n 25 security.log | wc -l")

#solved([5. Extract lines 21 to 30 from `login.log` and count the extracted lines.], "head -n 30 login.log | tail -n 10 | wc -l")

#solved([6. Extract lines 51 to 60 from `access.log` and count the extracted lines.], "head -n 60 access.log | tail -n 10 | wc -l")

#solved([7. Extract events 101 to 150 from `incident.log` and count how many are displayed.], "head -n 150 incident.log | tail -n 50 | wc -l")

#solved([8. First 100 events from `incident.log`, take the last 20 of that output, count the lines.], "head -n 100 incident.log | tail -n 20 | wc -l")
