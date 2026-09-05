#import "/template/lib.typ": *
#import "@preview/codly:1.3.0" as codly
#import "@preview/cetz:0.4.2"

#show: assignment.with(
  title: "Investigating the Linux Filesystem",
  number: "Assignment 03",
  kind: "Theory",
  keywords: ("linux", "filesystem", "FHS", "lsblk", "/proc", "mount point"),
  date: datetime(year: 2026, month: 9, day: 4),
)

#set heading(numbering: none)
#show figure.where(kind: table): set block(breakable: true)

Linux keeps one directory tree rooted at `/`, with no drive letters. A disk is
cut into partitions, each partition is formatted with a filesystem, and each
filesystem is attached to the tree at a directory called its mount point. The
sections below follow the exercise order and read that stack from the block
devices up, then walk the standard directories.

#text(style: "italic", fill: theme.muted)[The device names, sizes, and UUIDs in
Exercises 1, 2, and 16 are from the representative single-disk Linux system
used here. Read the real values from `lsblk` and `df` on the machine under
examination.]

= Exercise 1: Identify the filesystem

```bash
lsblk        # devices and partitions
lsblk -f     # add filesystem type, label, UUID, mount point
df -T        # filesystem type per mount
df -h        # size, used, available, use%
```

#codly.no-codly[
```
❯ lsblk                                  ❯ df -h
NAME   MAJ:MIN RM  SIZE TYPE MOUNTPOINTS  Filesystem  Size  Used Avail Use% Mounted on
sda      8:0    0   30G disk              /dev/sda2    29G  9.0G   18G  33% /
├─sda1   8:1    0  512M part /boot/efi    /dev/sda1   511M  6.1M  505M   2% /boot/efi
└─sda2   8:2    0 29.5G part /            tmpfs       1.9G  1.6M  1.9G   1% /run
sr0     11:0    1 1024M rom
```
]

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, right, left),
    [Device/Partition], [Filesystem], [Size], [Mount point],
    [`/dev/sda`], [--- (whole disk)], [30 G], [--- not mounted],
    [`/dev/sda1`], [`vfat` (FAT32)], [512 M], [`/boot/efi`],
    [`/dev/sda2`], [`ext4`], [29.5 G], [`/`],
    [`/dev/sr0`], [--- (optical, empty)], [1024 M], [--- not mounted],
  ),
  caption: [Storage configuration from `lsblk -f` and `df`.],
) <tbl-storage>

One disk, `/dev/sda`, carries two partitions: a `vfat` EFI partition at
`/boot/efi` and the `ext4` root at `/`. So `/` sits on `/dev/sda2`, type `ext4`,
using 9.0 G of 29 G (33%). Swap here is a file (`/swapfile`), not a partition, and
any loop mounts (`loop0`, `loop1`) are left out of @tbl-storage as they are not
disk partitions.

= Exercise 2: Disk to mount point

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let node(y, label, val) = {
      rect((0, y), (7.4, y + 0.9), stroke: 0.6pt + theme.rule, fill: theme.head-fill)
      content((3.7, y + 0.45))[#strong[#label]#h(0.6em)#text(fill: theme.muted)[#val]]
    }
    node(6, [Disk], [`/dev/sda`, 30 G])
    node(4, [Partition], [`/dev/sda2`, 29.5 G])
    node(2, [Filesystem], [`ext4`])
    node(0, [Mount point], [`/`])
    line((3.7, 6), (3.7, 4.9), mark: (end: ">"))
    line((3.7, 4), (3.7, 2.9), mark: (end: ">"))
    line((3.7, 2), (3.7, 0.9), mark: (end: ">"))
  }),
  caption: [Storage of `/dev/sda2`, disk to mount point. The EFI partition runs
    the same chain: `/dev/sda` to `/dev/sda1` to `vfat` at `/boot/efi`.],
)

The layers depend on each other in order. A disk is unusable until it holds a
partition, a partition is dead space until a filesystem is written on it, and a
filesystem stays unreachable until it is mounted onto a directory. The mount
point is where the storage joins the paths that commands actually use.

= Exercise 3: Explore the root filesystem

```bash
pwd; cd /; pwd    # /home/n10nce  ->  /
ls /              # visible children of /
ls -a /           # add hidden entries
```

The direct children of `/` are all directories:

#codly.no-codly[
```
❯ ls /
bin  boot  dev  etc  home  lib  lib64  lost+found  media  mnt
opt  proc  root  run  sbin  srv  sys   tmp         usr    var
```
]

On a merged-`/usr` layout, `/bin`, `/sbin`, and `/lib` are symlinks into
`/usr`. Comparing `ls` with `ls -a` adds only `.` and `..`. The root holds no
other hidden entries, since dotfiles belong in home directories.

= Exercise 4: Hierarchy investigation

Each location was listed with `ls` (and `ls -a` where useful).

#figure(
  table(
    columns: (auto, 1.25fr, 1.55fr),
    align: (left, left, left),
    [Directory], [Example contents], [Purpose],
    [`/home`], [`n10nce/`, other users, `lost+found/`],
      [Home directories of ordinary users.],
    [`/root`], [`.bashrc`, `.ssh/`, `.cache/`],
      [Home of the superuser, kept off `/home` so root can log in when `/home` is not mounted.],
    [`/etc`], [`passwd`, `fstab`, `hostname`, `ssh/`],
      [System-wide configuration, as editable text; no binaries.],
    [`/var`], [`log/`, `cache/`, `spool/`, `lib/`],
      [Variable data that grows and changes at runtime.],
    [`/var/log`], [`syslog`, `auth.log`, `journal/`],
      [System and application log files.],
    [`/tmp`], [`.X11-unix/`, `.ICE-unix/`, `systemd-private-*`],
      [Temporary scratch space, world-writable with sticky bit, cleared on reboot.],
    [`/usr`], [`bin/`, `lib/`, `share/`, `local/`],
      [Installed, mostly read-only programs and shared data.],
    [`/boot`], [`vmlinuz-*`, `initrd.img-*`, `grub/`],
      [Kernel, initial RAM disk, and bootloader.],
    [`/dev`], [`null`, `zero`, `sda`, `tty`],
      [Device nodes: the file interface to hardware and pseudo-devices.],
    [`/proc`], [`cpuinfo`, `meminfo`, numbered PID dirs],
      [Virtual filesystem exposing kernel and per-process state.],
  ),
  caption: [Standard directories and their purpose (Filesystem Hierarchy Standard).],
) <tbl-fhs>

= Exercise 5: Find the home directory

```bash
whoami                  # n10nce
echo "$HOME"            # /home/n10nce
cd ~ && pwd             # /home/n10nce
ls ; ls -a              # normal, then all entries
```

`whoami` gives `n10nce` and `$HOME` gives `/home/n10nce`, found without assuming
the path. A plain `ls` shows `Desktop`, `Downloads`, `cyber_lab`, and the like;
`ls -a` adds the dotfiles `.bashrc`, `.profile`, `.bash_history`, `.config/`,
`.ssh/`, and the entries `.` and `..`.

= Exercise 6: Hidden files

```bash
ls        # visible only
ls -a     # include dot names
```

The extra entries are the dot-names, for example `.bashrc` (a file) and `.ssh`
(a directory).

+ *How does Linux identify a hidden file?* By a leading dot in the name. It is a
  shell and `ls` convention, not a filesystem attribute or permission.

+ *Why does a normal `ls` not display them?* `ls` filters out names starting
  with `.` by default; `-a` turns the filter off. The behaviour started as a
  quirk of early Unix `ls` and was kept to hide config files.

+ *What do `.` and `..` mean?* `.` is the current directory and `..` its parent.
  Both are real entries in every directory, which is what makes `./x` and `../x`
  work.

+ *Can a hidden file still be accessed if the name is known?* Yes. Hiding only
  affects listing. `cat ~/.bashrc` reads it, subject to the usual permissions.

+ *Why not assume a hidden file is safe or malicious?* The dot prefix carries no
  security meaning. Most dot-entries are ordinary config, yet the same trick
  hides payloads, stolen data, or a rogue key in `.ssh`. Judge the file by its
  content, owner, and timestamps, not by the fact it is hidden.

= Exercise 7: Build a filesystem hierarchy

```bash
mkdir -p cyber_lab/evidence/{network,system} cyber_lab/{logs,scripts,reports}
touch cyber_lab/evidence/network/traffic.txt \
      cyber_lab/evidence/system/processes.txt \
      cyber_lab/logs/security.log \
      cyber_lab/scripts/check.sh \
      cyber_lab/reports/investigation.txt
tree cyber_lab
```

Brace expansion builds the whole tree in one `mkdir -p`, which also creates
parents and ignores directories that already exist.

#codly.no-codly[
```
❯ tree cyber_lab
cyber_lab
├── evidence
│   ├── network/traffic.txt
│   └── system/processes.txt
├── logs/security.log
├── reports/investigation.txt
└── scripts/check.sh

6 directories, 5 files
```
]

Where `tree` is absent, `find cyber_lab` or `ls -R cyber_lab` verifies the same
structure.

= Exercise 8: Absolute and relative paths

Starting in `~/cyber_lab`, with `pwd` after each step:

```bash
cd evidence/network   # /home/n10nce/cyber_lab/evidence/network  (relative)
cd /etc               # /etc                                    (absolute)
cd                    # /home/n10nce                             (shortest home)
cd cyber_lab/reports  # /home/n10nce/cyber_lab/reports           (relative)
cd ..                 # /home/n10nce/cyber_lab                   (one up)
```

An *absolute path* starts at `/` and names every component, so it points to the
same place from anywhere (`/home/n10nce/cyber_lab`). A *relative path* is read
from the current directory and does not start with `/` (`evidence/network`,
`../logs`). `/` is the fixed root, identical for everyone; `~` is a shell
shorthand for the current user's home (`$HOME`), so its value differs per user.

= Exercise 9: Identify file types

`file` names the type; the first character of `ls -l` encodes it (`-` regular,
`d` directory, `c` character device, `l` symlink).

#figure(
  table(
    columns: (auto, 1.4fr),
    align: (left, left),
    [Object], [Type],
    [`/etc/passwd`], [Regular file, ASCII text (`-`).],
    [`/etc`], [Directory (`d`).],
    [`/bin/bash`], [Regular file, an ELF executable (via the `/bin -> /usr/bin` symlink).],
    [`/dev/null`], [Character special device (`c`).],
    [`/proc`], [Directory, the mount point of the `proc` virtual filesystem.],
    [`security.log`], [Regular file, empty as created.],
    [`check.sh`], [Regular file, empty until a shebang and code make it a shell script.],
  ),
  caption: [Classification of each object.],
) <tbl-filetypes>

= Exercise 10: Examine file metadata

```bash
echo "Investigation opened 2026-09-04" > investigation.txt
ls -l investigation.txt ; stat investigation.txt
```

#codly.no-codly[
```
❯ ls -l investigation.txt
-rw-r--r-- 1 n10nce n10nce 32 Sep  4 07:14 investigation.txt
❯ stat investigation.txt
  File: investigation.txt   Size: 32   Blocks: 8   regular file
Inode: 262147   Links: 1   Access: (0644/-rw-r--r--)  Uid: (1000/n10nce) Gid: (1000/n10nce)
Access: 2026-09-04 07:15:12   Modify: 2026-09-04 07:14:58   Change: 2026-09-04 07:14:58
```
]

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [Attribute], [Value], [Attribute], [Value],
    [Filename], [`investigation.txt`], [Inode], [262147],
    [Size], [32 bytes], [Access (atime)], [07:15:12],
    [Type], [regular file], [Modify (mtime)], [07:14:58],
    [Owner / Group], [`n10nce` / `n10nce`], [Change (ctime)], [07:14:58],
  ),
  caption: [Metadata reported by `stat`.],
) <tbl-stat>

+ *What is metadata?* Data about the file rather than its bytes: name, size,
  type, owner, group, permissions, link count, inode, and timestamps, held in
  the inode.

+ *Is metadata the same as content?* No. Content is the byte stream (`cat`);
  metadata describes it and lives in the inode.

+ *Which timestamp changes when contents are modified?* The modify time
  (mtime). The change time (ctime) also updates, because size and block count
  change with it. atime tracks reads and, under the usual `relatime` option, is
  not touched on every read.

= Exercise 11: Explore `/etc`

```bash
ls /etc | head
cat /etc/passwd /etc/group /etc/hostname /etc/hosts
```

A `passwd` line has seven colon-separated fields, for example
`n10nce:x:1000:1000:Anish Shobith P S,,,:/home/n10nce:/bin/bash`. A `group` line
holds the group name, its GID, and the member list (`n10nce:x:1000:`); `hosts`
maps names to addresses (`127.0.0.1 localhost`).

+ *What is stored under `/etc`?* Host-wide configuration as text files: accounts,
  groups, mounts, hostname, name resolution, and service settings. No programs
  or variable data.

+ *What does `/etc/passwd` contain?* One line per account with username, a
  password placeholder `x` (the hash sits in root-only `/etc/shadow`), UID, GID,
  the comment field, home directory, and login shell.

+ *What does `/etc/hostname` contain?* A single line with the system's static
  hostname, read at boot.

+ *Why is `/etc` security-sensitive?* It configures who may log in and with what
  rights: `passwd`, `sudoers`, the PAM stack, `cron`, and `hosts`. Reading it
  maps the users and services; writing it (root only) can plant a backdoor
  account, grant sudo, or redirect a hostname.

= Exercise 12: Explore log storage

```bash
ls -l  /var/log
ls -lt /var/log | head          # most recently modified
```

`/var/log` holds files (`syslog`, `auth.log`, `kern.log`, `wtmp`) and
directories (`journal/`). `syslog` and `journal/` change constantly, so they top
`ls -lt`. Some logs are world-readable, but `syslog`, `auth.log`, and `kern.log`
are mode `0640` restricted to root and the `adm` group, so a normal user needs
`sudo`.

+ *Why keep logs?* For a timestamped record of kernel, service, and
  authentication events, used in troubleshooting and audit.

+ *Why are logs useful in an incident?* They give the timeline: `auth.log` shows
  logins, `sudo`, and SSH, while `syslog` and the journal show service and
  kernel events. Gaps or truncation are themselves a sign of tampering.

+ *Why restrict some logs?* Authentication logs expose usernames and source
  addresses and are the first thing an intruder edits, so they are limited to
  root and `adm`.

= Exercise 13: Investigate `/tmp`

```bash
ls -la /tmp ; ls -lt /tmp | head ; ls -ld /tmp   # entries, recency, sticky bit
```

`/tmp` usually holds per-service scratch dirs (`systemd-private-*`, `.X11-unix/`,
`.ICE-unix/`), some owned by `root` and some by the logged-in user, with a few
dot-names among them. The directory is mode `1777` (`drwxrwxrwt`): anyone may
write, but the sticky bit means a user can delete only their own files.

*Why does `/tmp` matter in an investigation?* It is world-writable, so any
process can drop files there without privilege. Attackers use it to stage
downloaded tools, unpack exploits, and hold short-lived droppers or captured
credentials, trusting that reboot clears the traces. Recent or executable files
in `/tmp` (and `/var/tmp`, `/dev/shm`) are worth checking early.

= Exercise 14: Explore `/proc`

```bash
head /proc/cpuinfo /proc/meminfo   # CPU and memory info
echo $$                            # PID of this shell, e.g. 2417
ls -d /proc/$$                     # matching per-process directory exists
```

+ *What does `/proc/cpuinfo` give?* One block per logical CPU: model, vendor,
  clock speed, cache size, core count, and feature flags.

+ *What does `/proc/meminfo` give?* Memory totals in kilobytes: `MemTotal`,
  `MemFree`, `MemAvailable`, `Buffers`, `Cached`, and swap.

+ *Why the numbered directories?* One per running process, named by PID, holding
  its `cmdline`, `fd/`, `maps`, and `status`. This is where `ps` and `top` read
  from.

+ *Is `/proc` an ordinary disk directory?* No. It is a virtual filesystem of
  type `proc`, generated in memory; its files read as size zero and are produced
  by the kernel on access.

+ *Why is `/proc` useful in a security check?* It is a live view. `/proc/<pid>/`
  exposes each process's command line, binary, memory map, and environment, and
  comparing it against `ps` can reveal a process hidden by a rootkit.

= Exercise 15: Explore `/dev`

```bash
ls /dev | head
ls -l /dev/null /dev/zero   # crw-rw-rw-, major:minor 1,3 and 1,5
```

+ *What does `/dev` represent?* The system's devices exposed as files, both
  hardware and kernel pseudo-devices, backed by `devtmpfs`.

+ *Are the entries ordinary files?* No. They are device nodes, character or
  block special files named by a major and minor number, not stored bytes.

+ *File type of `/dev/null`?* A character special file; `ls -l` shows `c`.

+ *Why expose devices as files?* Under "everything is a file", the same `open`,
  `read`, and `write` calls work on devices as on files. Writing to `/dev/null`
  discards data, reading `/dev/zero` yields endless null bytes.

= Exercise 16: Filesystem space

```bash
df -h /               # capacity, used, available, use%
du -sh ~ ~/cyber_lab  # size of home and of the Exercise 7 tree
```

#codly.no-codly[
```
❯ df -h /
Filesystem  Size  Used Avail Use% Mounted on
/dev/sda2    29G  9.0G   18G  33% /
❯ du -sh ~ ~/cyber_lab
412M  /home/n10nce
32K   /home/n10nce/cyber_lab
```
]

Root holds 29 G, 9.0 G used, 18 G free, 33% full. Home takes about 412 M, of
which the new `cyber_lab` tree is only 32 K, since its five files are empty and
the space is just the directory entries.

*`df` versus `du`.* `df` reports per filesystem, reading the totals the
filesystem itself keeps: capacity, used, available, use% for each mount. `du`
reports per file, walking a tree and summing the blocks its files use. `df`
answers how full a partition is; `du` answers how much a directory consumes.
The two can disagree, for instance when a deleted file is still held open, where
`df` counts the space but `du` no longer sees the name.

= Exercise 17: Investigation scenario

Examining only the filesystem of a host reported as compromised, these are the
directories worth opening and the evidence in each.

#figure(
  table(
    columns: (auto, 1.6fr),
    align: (left, left),
    [Location], [Why, and what to expect],
    [`/var/log`], [The timeline: `auth.log` for logins, `sudo`, and SSH; `syslog` and the journal for service and kernel events. Gaps mean cleared tracks.],
    [`/etc`], [Persistence and account tampering: rogue `passwd`/`shadow` entries, added `sudoers` rights, malicious `cron`, altered `hosts`.],
    [`/home`], [User-level traces: `.bash_history`, keys and `authorized_keys` in `.ssh/`, downloads, and files staged for exfiltration.],
    [`/root`], [The superuser's home. If root was reached, check `.bash_history` and `.ssh/authorized_keys` for an added key.],
    [`/tmp`], [Staging ground: dropped tools, unpacked exploits, and short-lived binaries in a world-writable, reboot-cleared directory (with `/var/tmp`, `/dev/shm`).],
    [`/proc`], [On a live host, the running state: process command lines, open files, connections, and a process's environment; finds hidden processes.],
    [`/dev`], [Lower priority. Checked for anomalies: regular files hidden among the device nodes, and `/dev/shm` used as writable staging.],
  ),
  caption: [Locations selected for the investigation and their evidence.],
) <tbl-investigation>

The strongest sources are `/var/log`, `/etc`, `/home`, `/root`, and `/tmp`,
which cover timeline, persistence, user activity, and staging. `/proc` is
decisive while the machine still runs but is a live view, not stored evidence,
and `/dev` is only a targeted check for concealment.
