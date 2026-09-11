#import "/template/lib.typ": *

#show: assignment.with(
  title: "Command-Line Arguments, File Test Operators, and Filters",
  number: "Assignment 05",
  kind: "Theory",
  keywords: ("bash", "positional parameters", "file test operators", "grep", "head"),
  date: datetime(year: 2026, month: 9, day: 11),
)

#set heading(numbering: "1.")

Arguments arrive as `$1`, `$2`, ..., with `$#` the count. File tests inside
`[ ... ]`: `-e` exists, `-f` regular file, `-d` directory, `-r`/`-w`/`-x`
readable/writable/executable, `-s` non-empty. Each script was `chmod +x`'d and
run.

= Problem 1: First five lines of a named file

```bash
#!/bin/bash
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <filename>" >&2
    exit 1
fi
file="$1"
if [ -f "$file" ]; then
    echo "First 5 lines of '$file':"
    head -n 5 "$file"
else
    echo "Error: '$file' does not exist or is not a regular file." >&2
    exit 1
fi
```

`[ "$#" -eq 0 ]` catches the missing argument; `-f` rejects a missing file or a
directory before `head` runs.

= Problem 2: File type and permission checker

```bash
#!/bin/bash
path="$1"
[ "$#" -eq 0 ] && { echo "Usage: $0 <path>" >&2; exit 1; }
[ ! -e "$path" ] && { echo "Error: '$path' does not exist." >&2; exit 1; }

if   [ -f "$path" ]; then echo "'$path' is a regular file."
elif [ -d "$path" ]; then echo "'$path' is a directory."
else echo "'$path' is neither a regular file nor a directory."; fi

[ -r "$path" ] && echo "  readable:   yes" || echo "  readable:   no"
[ -w "$path" ] && echo "  writable:   yes" || echo "  writable:   no"
[ -x "$path" ] && echo "  executable: yes" || echo "  executable: no"
```

`-f`/`-d` give the type; `-r`/`-w`/`-x` report the access the current user has, so
a mode-444 file shows writable as no.

= Problem 3: Scan a log for suspicious keywords

```bash
#!/bin/bash
logfile="$1"
[ ! -f "$logfile" ] && { echo "Error: '$logfile' not a regular file." >&2; exit 1; }

grep -inE 'failed|denied|unauthorized|error' "$logfile"
echo "Total matching lines: $(grep -icE 'failed|denied|unauthorized|error' "$logfile")"
```

`-E` allows the `|` alternation, `-i` matches any case, `-n` adds line numbers,
`-c` gives the count.

= Problem 4: Existence, type, and emptiness check

```bash
#!/bin/bash
file="$1"
[ ! -e "$file" ] && { echo "'$file' does not exist."; exit 1; }
[ ! -f "$file" ] && { echo "'$file' is not a regular file."; exit 1; }

if [ -s "$file" ]; then
    echo "'$file' is non-empty. First 5 lines:"
    head -n 5 "$file"
else
    echo "'$file' is empty."
fi
```

Checks run general to specific: `-e`, then `-f`, then `-s` (true only when size
is above zero).

= Problem 5: `investigate.sh`

```bash
#!/bin/bash
logfile="$1"
[ ! -f "$logfile" ] && { echo "Error: '$logfile' not a regular file." >&2; exit 1; }
[ ! -r "$logfile" ] && { echo "Error: '$logfile' not readable." >&2; exit 1; }

read -r -p "Enter search term: " term
echo "First 5 matching records for '$term':"
grep -i -- "$term" "$logfile" | head -n 5
echo "Total matching records: $(grep -ic -- "$term" "$logfile")"
```

`-f` then `-r` guard the file; `read -r -p` prompts and stores the term; `head -n
5` shows five records while `grep -ic` reports the true total.
