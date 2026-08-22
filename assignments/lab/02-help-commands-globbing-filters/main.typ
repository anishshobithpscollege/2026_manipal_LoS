#import "/template/lib.typ": *

#show: assignment.with(
  title: "Getting Help, Basic Commands, Globbing and Filters",
  number: "Assignment 02",
  kind: "Lab",
  date: datetime(year: 2026, month: 8, day: 22),
)

#let shot(cap) = figure(
  kind: image,
  supplement: [Figure],
  rect(
    width: 100%, height: 5cm, radius: 4pt, inset: 8pt,
    stroke: (paint: theme.rule, thickness: 0.7pt, dash: "dashed"),
    fill: theme.head-fill,
    align(center + horizon, text(fill: theme.muted, style: "italic")[Attach screenshot here]),
  ),
  caption: cap,
)

#let ss = box(
  width: 100%, height: 2.4cm, radius: 3pt, inset: 4pt,
  stroke: (paint: theme.rule, thickness: 0.6pt, dash: "dashed"),
  fill: theme.head-fill,
  align(center + horizon, text(0.8em, fill: theme.muted, style: "italic")[screenshot]),
)

#let shotband(path) = layout(sz => {
  let full = image(path, width: sz.width)
  if measure(full).height > 12cm { align(center, image(path, height: 12cm)) } else { full }
})

#let ssband = box(
  width: 100%, height: 3cm, radius: 3pt,
  stroke: (paint: theme.rule, thickness: 0.6pt, dash: "dashed"),
  fill: theme.head-fill,
  align(center + horizon, text(0.85em, fill: theme.muted, style: "italic")[screenshot]),
)

#let refcols = (3fr, 1.3fr, 2.4fr, 2fr)
#let refhead = ([Task], [Command], [Syntax], [Example])

#let ref-taskline(r) = grid(
  columns: refcols,
  inset: 7pt,
  stroke: (x: 0.5pt + theme.rule, y: none),
  r.at(0), r.at(1), r.at(2), r.at(3),
)

#let ref-entry(r) = {
  let p = r.at(4, default: none)
  table.cell(colspan: 4, inset: 0pt, breakable: false,
    if p == false { ref-taskline(r) } else {
      stack(spacing: 5pt, ref-taskline(r), if p == none { ssband } else { shotband(p) })
    },
  )
}

#let ref-section(title, intro, rows) = page(flipped: true, {
  heading(level: 1, title)
  intro
  v(0.4em)
  table(
    columns: refcols,
    table.header(..refhead),
    ..rows.map(ref-entry),
  )
})

= Aim

The aim of this lab is to practise the following on the Linux command line:

+ Getting help
+ Basic commands
+ Navigation
+ File system
+ Simple shell script
+ Globbing
+ Extended globbing
+ Filters: `head`, `tail`, `wc`

#ref-section(
  [Getting Help],
  [Linux keeps a manual for its commands, along with lookup commands that report
   where a command lives, what type it is, and how to use it.],
  (
    ([Manual page for a known command], [`man`], [`man <command>`], [`man ls`], "assets/man-ls.png"),
    ([Search for an unknown command by keyword], [`apropos`], [`apropos <keyword>` \ (`man -k <keyword>`)], [`apropos copy`], "assets/apropos-copy.png"),
    ([Locate the binary and source of a command], [`whereis`], [`whereis <command>`], [`whereis ls`], "assets/whereis-ls.png"),
    ([Path of the command that will run], [`which`], [`which <command>`], [`which ls`], "assets/which-ls.png"),
    ([Whether a command is external or internal], [`type`], [`type <command>`], [`type cd`], "assets/type-cd.png"),
    ([Help for an internal (builtin) command], [`help`], [`help <builtin>`], [`help cd`], "assets/help-cd.png"),
    ([List out all bash commands], [`compgen`], [`compgen -c` \ (`-b` builtins, `-a` aliases)], [`compgen -c`], "assets/compgen-c.png"),
    ([Usage / short description of a command], [`whatis`], [`whatis <command>` \ (`<command> --help`)], [`whatis ls`], "assets/whatis-ls.png"),
  ),
)

#ref-section(
  [Basic Commands],
  [These commands report system information and handle everyday tasks: the date
   and calendar, the kernel and shell, disk space, the logged in user, aliases,
   file timestamps, and powering the machine off or on.],
  (
    ([Today's date], [`date`], [`date`], [`date`], "assets/date.png"),
    ([Print calendar], [`cal`], [`cal` \ (`cal <month> <year>`)], [`cal 8 2026`], "assets/cal.png"),
    ([Print kernel version], [`uname`], [`uname -r` \ (`uname -a` for all)], [`uname -r`], "assets/uname-r.png"),
    ([Print default shell], [`echo`], [`echo $SHELL`], [`echo $SHELL`], "assets/echo-shell.png"),
    ([Currently logged-in user], [`whoami`], [`whoami`], [`whoami`], "assets/whoami.png"),
    ([Create a shortcut for a command], [`alias`], [`alias name='command'`], [`alias ll='ls -l'`], "assets/alias.png"),
    ([Delete a shortcut], [`unalias`], [`unalias name`], [`unalias ll`], "assets/unalias.png"),
    ([Change the timestamp of a file], [`touch`], [`touch <file>` \ (`-d`, `-t` to set)], [`touch -t 08201200 a.txt`], "assets/touch-timestamp.png"),
    ([Clear the screen], [`clear`], [`clear`], [`clear`], "assets/clear.png"),
    ([Create empty files], [`touch`], [`touch <file>...`], [`touch a.txt b.txt`], "assets/touch-create.png"),
    ([Know disk usage], [`du`], [`du -h <path>`], [`du -h ~`], "assets/du.png"),
    ([Know free space in the system], [`df`], [`df -h`], [`df -h`], "assets/df.png"),
    ([Know about the Linux release], [`lsb_release`], [`lsb_release -a`], [`lsb_release -a`], "assets/lsb-release.png"),
    ([Show login history], [`last`], [`last`], [`last`], "assets/last.png"),
    ([Check current user privileges], [`id`], [`id` \ (`sudo -l` for sudo rights)], [`id`], "assets/id.png"),
    ([Find about the Linux release], [`cat`], [`cat /etc/os-release` \ (`hostnamectl`)], [`cat /etc/os-release`], "assets/cat-os-release.png"),
    ([Check system uptime], [`uptime`], [`uptime`], [`uptime`], "assets/uptime.png"),
    ([Shutdown], [`shutdown`], [`sudo shutdown now` \ (`poweroff`)], [`sudo shutdown now`], false),
    ([Restart], [`reboot`], [`sudo reboot` \ (`shutdown -r now`)], [`sudo reboot`], false),
  ),
)

#ref-section(
  [Navigation],
  [The `cd` command changes the working directory. The rows below reach the home,
   parent, child, previous, and root directories. `pushd` is an alternative that
   also records the directory I left, so `popd` returns to it.],
  (
    ([Navigate to the home directory], [`cd`], [`cd` \ (`cd ~`)], [`cd ~`], "assets/cd-home.png"),
    ([Navigate to the parent directory], [`cd ..`], [`cd ..`], [`cd ..`], "assets/cd-parent.png"),
    ([Navigate to a child directory], [`cd`], [`cd <directory>`], [`cd Documents`], "assets/cd-child.png"),
    ([Alternate command to `cd`], [`pushd`], [`pushd <directory>` \ (`popd` to return)], [`pushd /tmp`], "assets/pushd.png"),
    ([Go back to the previous directory], [`cd -`], [`cd -`], [`cd -`], "assets/cd-prev.png"),
    ([Go to the root directory], [`cd /`], [`cd /`], [`cd /`], "assets/cd-root.png"),
  ),
)

#ref-section(
  [File System],
  [This command reports the type of file system mounted at a given path.],
  (
    ([Identify the file system (type)], [`df -T`], [`df -T <path>` \ (`lsblk -f`, `blkid`)], [`df -T /`], "assets/df-t.png"),
  ),
)

= Simple Shell Script

The script below lists the sample log files in the current directory using the
`*.log` glob.

*Script* (`logfiles.sh`):

```bash
#!/bin/bash
# logfiles.sh -- list the sample log files
echo "Sample log files:"
ls *.log
```

Make it executable and run it from the directory that holds the logs:

```bash
chmod +x logfiles.sh
./logfiles.sh
```

#include "solutions.typ"
