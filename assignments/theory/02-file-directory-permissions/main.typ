#import "/template/lib.typ": *

#show: assignment.with(
  title: "Comparing Permissions on Regular Files and Directories",
  number: "Assignment 02",
  kind: "Theory",
  keywords: ("linux", "file permissions", "chmod", "directory permissions"),
  date: datetime(year: 2026, month: 8, day: 22),
)

#show figure.where(kind: table): set block(breakable: true)

A Linux permission mode is three bits per class of user, written in octal as
`r` = 4, `w` = 2, `x` = 1, so a single digit encodes one class: `7` is `rwx`,
`6` is `rw-`, `5` is `r-x`, and so on. The bits carry different meanings
depending on whether the object is a regular file (a stream of bytes) or a
directory (a table that maps names to inodes).

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: (center, left, left),
    [Bit], [On a regular file], [On a directory],
    [`r` (4)], [Read the file's contents (`cat`, `cp`).],
      [Read the list of entry names it holds (`ls`).],
    [`w` (2)], [Change the contents: append, overwrite, or truncate.],
      [Add, remove, or rename entries. Effective only together with `x`.],
    [`x` (1)], [Run the file as a program. A script also needs `r`.],
      [Enter (`cd`) and traverse it, resolving a name to reach an entry.],
  ),
  caption: [Meaning of the three permission bits for a file and a directory.],
)

= Setup

A regular file, a directory, and one file inside that directory are created. For
the execution cases, `sample.txt` holds a one-line shell script so that running
it produces visible output.

```bash
printf '#!/bin/bash\necho "script ran"\n' > sample.txt   # regular file (a script)
mkdir sample_dir                                          # directory
echo "inside" > sample_dir/inside.txt                     # one file inside it
ls -ld sample.txt sample_dir                              # confirm both exist
```

= Comparison

Each mode below is applied to both subjects with `chmod`, and the listed
operations are attempted. The result of every operation is given in
@tbl-compare; the commands that produce each row follow in @sec-cmds.

#figure(
  table(
    columns: (auto, 1fr, 1.35fr, 1fr, 1.35fr),
    align: (center + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    [Permission],
    [`sample.txt` - test], [Result],
    [`sample_dir` - test], [Result],

    [400 \ (`r--`)],
    [read; modify],
    [Read succeeds; modify denied (`Permission denied`).],
    [list; enter],
    [Entry names are listed; `ls -l` details and `cd` are denied.],

    [200 \ (`-w-`)],
    [read; modify],
    [Read denied; modify (append / overwrite) succeeds.],
    [list; enter; create],
    [All three denied: write alone is unusable without execute.],

    [100 \ (`--x`)],
    [read; execute],
    [Read denied; the script does not run either, because the interpreter must read it.],
    [list; enter],
    [Listing denied; `cd` into the directory succeeds.],

    [500 \ (`r-x`)],
    [read; modify],
    [Read succeeds; modify denied; execution succeeds.],
    [list; enter],
    [List and enter succeed; creating or deleting entries denied.],

    [600 \ (`rw-`)],
    [read; modify],
    [Read and modify both succeed (no `x`, so it will not run).],
    [list; enter; create],
    [Names are listed, but `cd` and creation are denied: write needs execute.],

    [700 \ (`rwx`)],
    [read; modify; execute],
    [All three succeed.],
    [list; enter; create; delete],
    [All four succeed: complete control.],
  ),
  caption: [Result of each operation on the file and on the directory, by mode.],
) <tbl-compare>

Two results are worth flagging, because both are commonly assumed the other way:

- *Execute alone does not run a script.* At mode `100` the file has `x` but not
  `r`, and the script is refused. A compiled binary runs with `x` alone, but an
  interpreted script also needs `r`, since the interpreter opens and reads the
  file to run it.
- *Write alone cannot change a directory.* At modes `200` and `600` the
  directory has `w` but not `x`, and no file can be created inside it. The entry
  table can be modified only while the directory is traversable, which needs
  `x`.

= Commands used <sec-cmds>

Each block applies one mode to both subjects and attempts the operations. The
comment after each command states the result for a normal user (the owner).

== 400 (`r--`)

```bash
chmod 400 sample.txt sample_dir
cat sample.txt          # read   -> contents printed
echo x >> sample.txt    # modify -> Permission denied
ls sample_dir           # list   -> entry names shown
ls -l sample_dir        # detail -> Permission denied
cd sample_dir           # enter  -> Permission denied
```

== 200 (`-w-`)

```bash
chmod 200 sample.txt sample_dir
cat sample.txt          # read   -> Permission denied
echo x >> sample.txt    # modify -> appended, succeeds
ls sample_dir           # list   -> Permission denied
cd sample_dir           # enter  -> Permission denied
touch sample_dir/new    # create -> Permission denied
```

== 100 (`--x`)

```bash
chmod 100 sample.txt sample_dir
cat sample.txt          # read    -> Permission denied
./sample.txt            # execute -> Permission denied (script needs read too)
ls sample_dir           # list    -> Permission denied
cd sample_dir           # enter   -> succeeds
```

== 500 (`r-x`)

```bash
chmod 500 sample.txt sample_dir
cat sample.txt          # read    -> contents printed
echo x >> sample.txt    # modify  -> Permission denied
./sample.txt            # execute -> "script ran"
ls sample_dir           # list    -> entry names shown
cd sample_dir           # enter   -> succeeds
touch sample_dir/new    # create  -> Permission denied
```

== 600 (`rw-`)

```bash
chmod 600 sample.txt sample_dir
cat sample.txt          # read   -> contents printed
echo x >> sample.txt    # modify -> appended, succeeds
ls sample_dir           # list   -> entry names shown
cd sample_dir           # enter  -> Permission denied
touch sample_dir/new    # create -> Permission denied
```

== 700 (`rwx`)

```bash
chmod 700 sample.txt sample_dir
cat sample.txt              # read    -> contents printed
echo x >> sample.txt        # modify  -> appended, succeeds
./sample.txt                # execute -> "script ran"
ls sample_dir               # list    -> entry names shown
cd sample_dir               # enter   -> succeeds
touch sample_dir/new        # create  -> succeeds
rm sample_dir/inside.txt    # delete  -> succeeds
```

= Review Questions

+ *What does read (`r`) permission allow with a regular file?* \
  The file's contents can be opened and read, for example with `cat`, `less`, or
  `cp`. It does not permit any change to the file.

+ *What does read (`r`) permission allow with a directory?* \
  The list of entry names the directory holds can be read (`ls`). On its own it
  does not allow entering the directory or reading each entry's metadata, such
  as size or permissions; that requires execute. This is why mode `400` on
  `sample_dir` lists names but refuses `ls -l` and `cd`.

+ *What does write (`w`) permission mean for a regular file?* \
  The file's contents can be changed: appended to, overwritten, or truncated. It
  controls the data inside the file, not the file's name within its folder.
  Renaming or deleting the file itself is governed by the write bit of the
  containing directory, not of the file.

+ *What does write (`w`) permission mean for a directory?* \
  The set of entries can be changed: creating, deleting, and renaming files
  inside it. It takes effect only together with execute, because the directory
  must be traversable before its entries can be altered, which is why modes
  `200` and `600` cannot create a file.

+ *What does execute (`x`) permission mean for a regular file?* \
  The file can be run as a program. A compiled binary needs only execute, but an
  interpreted script needs read and execute together, because the interpreter
  must read the file to run it. At mode `100` the script is therefore refused.

+ *Why is execute (`x`) permission important for accessing a directory?* \
  Execute is the directory's search bit. It grants the right to traverse the
  directory: to `cd` into it and to resolve a name inside it in order to open a
  file. Without it, even with read permission, only the bare name list is
  available and no file inside can be reached. Modes `100` (enter works, list
  fails) and `600` (list works, enter fails) together show the two rights are
  separate.

+ *Which permission combination allows the owner to fully access a regular
  file?* \
  `700` (`rwx`): the contents can be read, changed, and the file executed. Where
  execution is not required, `600` (`rw-`) already gives complete read and write
  access.

+ *Which permission combination allows the owner to fully access a directory?* \
  `700` (`rwx`): read to list the names, execute to enter and reach the entries,
  and write to create, rename, and delete entries.

+ *Why do the same `r`, `w`, and `x` bits behave differently for a regular file
  and a directory?* \
  Because a regular file and a directory are different kinds of object, so the
  bits act on different things. A regular file is a stream of bytes, and its
  bits act on that data: `r` reads the bytes, `w` changes the bytes, `x` runs
  the bytes as code. A directory is not byte data but a table mapping names to
  inodes, so the identical bits act on that table: `r` reads the table's names,
  `w` edits the table by adding or removing entries, and `x` grants the right to
  use the table to resolve a name and step inside. Reading the name list (`r`)
  and being allowed to use those names to reach anything (`x`) are separate
  operations on a directory, so `r` and `x` split apart there in a way they
  never do for a file. This is what the modes above show: write is useless
  without execute (modes `200` and `600` cannot create a file), while execute
  alone (mode `100`) allows entry and access by name yet hides the listing.
