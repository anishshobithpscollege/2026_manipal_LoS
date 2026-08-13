#import "/template/lib.typ": *

#show: assignment.with(
  title: "System Update and Tool Availability Check",
  number: "Assignment 01",
  kind: "Lab",
  date: datetime(year: 2026, month: 8, day: 11)
)

= Update the system

== Objective

Refresh the local package index and install available upgrades for every
installed package, so the system is up to date.

== Script

```bash
#!/bin/bash

echo "Updating the system..."
sudo apt-get update
sudo apt-get upgrade -y
echo "Done!"
```

== Explanation

- `#!/bin/bash` — the shebang, tells the OS to run the file with the Bash shell.
- `sudo` - runs the command with administrator (root) privileges, which package management requires.
- `apt-get update` - re reads the configured repositories and refreshes the local list of available packages and versions. It does not install anything.
- `apt-get upgrade -y` - installs the newest versions of packages already on the system, using the list refreshed above. `-y` answers "yes" to the confirmation prompt so the script runs unattended.
- `echo` - prints a message so the user can follow the script's progress.

== Output

#figure(
  image("assets/update1.png", width: 80%),
  caption: [Creating the `update.sh` script, making it executable, and starting the system upgrade],
)
#figure(
  image("assets/update2.png", width: 80%),
  caption: [Package configuration and trigger processing completing the upgrade],
)

= Check whether a tool is installed

== Objective

Prompt the user for the name of a tool (command) and report whether it is
available on the system.

== Script

```bash
#!/bin/bash

echo "Enter the name of the tool:"
read tool

if command -v $tool > /dev/null
then
    echo "$tool is installed."
else
    echo "$tool is not installed."
fi
```

== Explanation

- `read tool` - pauses and reads a line of input from the user, storing it in the variable `tool`.
- `command -v $tool` - looks up `$tool` and prints its path if it resolves to an executable, a shell built-in, or an alias. Its exit status is `0` when the tool is found and non zero otherwise.
- `> /dev/null` - discards the printed path, we only care about the exit status, not the output.
- `if ... then ... else ... fi` - branches on that exit status: the `then` block runs when the tool is found, the `else` block when it is not.

== Output

#figure(
  image("assets/check.png", width: 80%),
  caption: [Checking an installed tool and not installed tool.],
)
