#import "/template/lib.typ": *

#show: assignment.with(
  title: "Hard Links, Symbolic Links, and Sorting Security Logs",
  number: "Assignment 04",
  kind: "Theory",
  keywords: ("linux", "hard link", "symbolic link", "inode", "sort", "uniq"),
  date: datetime(year: 2026, month: 9, day: 11),
)

#set heading(numbering: "1.")
#show figure.where(kind: table): set block(breakable: true)

A hard link is a second name for the same inode. A symbolic link is a small file
that stores the pathname of another file. Inode numbers below are from one Linux
run.

= Part A: Create the links

```bash
mkdir link_lab && cd link_lab
printf 'Linux File System Security Lab\nConfidential Security Report\n' > security.txt
ln    security.txt security_hard.txt
ln -s security.txt security_soft.txt
ls -li security.txt security_hard.txt security_soft.txt
```

Inodes: `security.txt` 393227, `security_hard.txt` 393227, `security_soft.txt`
393230. Original and hard link share the inode; the soft link has its own.

= Part B: File metadata

First `ls -l` character: `-` for the original and hard link (regular files), `l`
for the soft link. Link count is 2 for the original and hard link, 1 for the soft
link, because the count belongs to the inode and the original is named twice.

#figure(
  table(
    columns: (1.3fr, 1fr, 1fr, 1fr),
    align: (left, left, left, left),
    [Parameter], [Original], [Hard link], [Soft link],
    [Inode number], [393227], [393227], [393230],
    [File type], [regular file], [regular file], [symbolic link],
    [Size], [60 bytes], [60 bytes], [12 bytes],
    [Link count], [2], [2], [1],
    [Permissions], [`-rw-r--r--`], [`-rw-r--r--`], [`lrwxrwxrwx`],
  ),
  caption: [`stat` values for the three names.],
) <tbl-stat>

The soft link is 12 bytes because it stores the path `security.txt`, which is 12
characters, not the target's data.

= Part C: `readlink`

```bash
readlink security_soft.txt
readlink security_hard.txt
readlink -f security_soft.txt
```

`readlink security_soft.txt` prints its stored target, `security.txt`. On the
hard link it prints nothing and returns exit status 1, because a hard link is a
regular file, not a symlink. `readlink -f` resolves the link to the absolute
canonical path, `/home/n10nce/link_lab/security.txt`.

= Part D: Content modification

```bash
echo 'Unauthorized login detected' >> security.txt
cat security.txt security_hard.txt security_soft.txt
echo 'Account locked after 3 attempts' >> security_hard.txt
```

The new line shows through all three names, and a line written through the hard
link is read back through the original and the soft link. One file, three names.

= Part E: Rename experiment

```bash
mv security.txt incident.txt
```

Hard link (`security_hard.txt`) still works: it points at the inode, not the
name. Soft link (`security_soft.txt`) breaks with `No such file or directory`,
since the name it stores is gone. `readlink security_soft.txt` still prints
`security.txt`. Renaming breaks the pathname binding of the soft link but not the
inode binding of the hard link.

= Part F: Deletion experiment

```bash
ln security.txt security_hard.txt ; ln -s security.txt security_soft.txt
rm security.txt
```

Hard link still works; its link count drops from 2 to 1. Soft link fails to open,
but `ls -l` still lists it and `readlink` still prints `security.txt` (a
*dangling / broken symbolic link*: the link exists, its target does not).

Deleting the original name does not delete the data while a hard link exists.
`rm` only decrements the link count; the inode and its blocks are freed when the
count reaches 0. Here it went 2 to 1, so the data stays reachable through
`security_hard.txt`.

= Part G: Directories and filesystems

```bash
mkdir evidence
ln    evidence evidence_hard
ln -s evidence evidence_link
```

Hard link to a directory is refused (`ln: evidence: hard link not allowed for
directory`), because it would risk cycles in the tree. Symbolic link to a
directory works. Across filesystems the hard link fails with `Invalid
cross-device link` (`EXDEV`), because inode numbers are per-filesystem; the
symbolic link works, because it stores a pathname.

= Final comparison

#figure(
  table(
    columns: (1.35fr, 1.15fr, 1.3fr),
    align: (left, left, left),
    [Parameter], [Hard link], [Symbolic link],
    [Inode number], [Same as target], [Own, different],
    [File type], [Regular file (`-`)], [Symbolic link (`l`)],
    [Link count], [Adds to target's (2)], [Own count 1],
    [File size], [Same as target (60 B)], [Length of path (12 B)],
    [Stores pathname?], [No], [Yes],
    [`readlink`], [None (exit 1)], [Prints the target path],
    [Modify target], [Visible], [Visible],
    [Rename target], [Still works], [Breaks],
    [Delete target], [Data persists], [Dangling],
    [Can break?], [No], [Yes],
    [Directory linking], [No], [Yes],
    [Cross-filesystem], [No (`EXDEV`)], [Yes],
  ),
  caption: [Hard link versus symbolic link.],
) <tbl-compare>

= Sorting alerts and logs

`alerts.txt` holds `IP username failed-attempts` per line: `192.168.1.10 admin
5`, `10.0.0.8 root 12`, `172.16.0.5 guest 2`, `10.0.0.20 admin 8`.

== Sort by failed attempts

```bash
sort -k3 -n alerts.txt
```

`-k3` picks the third field, `-n` compares it numerically; add `-r` for
descending.

== IP addresses alphabetically

```bash
sort -k1,1 alerts.txt
```

Text order, so `10.0.0.20` sorts before `10.0.0.8`, not as numeric addresses.

== Unique IP addresses

```bash
cut -d' ' -f1 alerts.txt | sort -u
```

== Port numbers ascending

```bash
sort -n ports.txt
```

== Port numbers descending

```bash
sort -nr ports.txt
```

== Usernames, case-insensitive

```bash
sort -f users.txt
```

`-f` folds upper and lower case together.

== Count per IP, most frequent first

```bash
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' auth.log | sort | uniq -c | sort -rn
```

`uniq -c` counts adjacent duplicates, so the input is sorted first.

== CSV, sort by failed attempts

```bash
sort -t, -k3 -nr logins.csv
```

`-t,` splits on commas so `-k3` is the `failed_attempts` field.

== CSV vulnerability report, sort by severity

```bash
{ head -1 vulns.csv; tail -n +2 vulns.csv | sort -t, -k3 -nr; }
```

`head -1` keeps the header row; `tail -n +2` sorts only the data rows.

== Extract IPs, then unique

```bash
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' auth.log | sort -u
```

== Top five IPs by failed logins

```bash
grep -i Failed auth.log | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn | head -5
```

The first `grep` keeps only `Failed` lines, so a successful login is not counted;
`head -5` keeps the five worst sources.
