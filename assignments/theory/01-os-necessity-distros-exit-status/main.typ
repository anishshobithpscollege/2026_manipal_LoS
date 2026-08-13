#import "/template/lib.typ": *

#show: assignment.with(
  title: "Operating Systems: Necessity, Security Distributions, and Exit Status",
  number: "Assignment 01",
  kind: "Theory",
  keywords: ("operating system", "linux", "cybersecurity distributions", "exit status"),
  date: datetime(year: 2026, month: 8, day: 13)
)

#show figure.where(kind: table): set block(breakable: true)

= What If There Were No Operating System?

== The role of an operating system

The operating system is the main program that runs the computer. It looks after the
processor, the memory, the storage, and the devices like the keyboard and screen,
and it lets a person use the machine without worrying about the hardware underneath.
Take it away and the computer is almost unusable, because every program would then
have to drive the hardware by itself.

== Problems faced without an operating system

#figure(
  table(
    columns: (auto, 1fr),
    [*Problem*], [*Why it is a problem*],
    [No multitasking], [Only one program can run at a time, so everything else waits until it finishes.],
    [No memory protection], [All programs share the same memory. A fault in one can overwrite another and bring the whole system down.],
    [No file system], [Data sits on the disk as plain blocks with no names or folders, so finding anything is hard.],
    [No device drivers], [Each program has to carry its own code for every device, like a printer or a disk. New hardware means rewriting programs.],
    [No access control], [There are no accounts or passwords, so any program or person can open or change any data.],
    [No user interface], [There is no shell and no ready-made system calls, so each program handles its own input and output from scratch.],
  ),
  caption: [What goes wrong when a computer has no operating system.],
)

== Main features of an operating system

/ Process management and multitasking: The operating system runs many programs
  together by giving each one a short turn on the processor, over and over, so they
  all seem to run at once. Each program runs as its own process. Without this, only
  one program could run and the rest would wait for it to finish.

/ Memory management: Each program gets its own block of memory, and the operating
  system keeps one program from touching another's. When memory fills up, it borrows
  some disk space, called swap, to keep going. Without this, one broken program
  could spoil the memory of every other program.

/ File and access management: The operating system keeps data as named files inside
  folders, so anything is easy to find. It also decides who may open or change each
  file, using permissions. Without this, data would be nameless blocks on the disk
  that anyone could read.

#pagebreak()

== Without OS versus With OS

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    [*Concern*], [*Without an OS*], [*With Linux*],
    [Running programs], [Only one at a time], [Many run together, sharing the processor],
    [Memory], [One shared space, so a fault spreads everywhere], [Each program gets its own memory, with swap as backup],
    [Storage], [Nameless blocks on the disk], [Named files and folders you can browse],
    [Hardware], [Each program needs its own driver for every device], [One set of drivers the system shares with all programs],
    [Security], [No accounts and no permissions], [Files have owners and `rwx` permissions the system checks],
    [Ease of use], [Every program builds its own input and output], [A shell, system calls, and libraries ready for all],
  ),
  caption: [Working without an operating system next to working with Linux.],
)

Put together, these features are the reason an operating system matters. It takes
bare hardware and turns it into a machine that runs many programs at once, keeps
them apart, and stores data in a tidy way.

= A Cybersecurity Lab: Choosing a Distribution

A security lab has to do several different jobs, and no single Linux distribution is
good at all of them. The four main jobs are penetration testing, digital forensics,
privacy, and monitoring, and each one has a distribution that fits it well.

== Comparison chart

#figure(
  table(
    columns: (auto, auto, 1fr, 1.3fr),
    [*Distribution*], [*Base*], [*Focus*], [*Main features*],
    [Kali Linux], [Debian], [Penetration testing], [Built by OffSec. Comes packed with around 600 security tools, plus a live mode for forensics that never writes to the disk being checked.],
    [Parrot Security], [Debian], [Pentesting and privacy], [Lighter than Kali. Carries testing, forensic, and privacy tools together, and includes AnonSurf to push traffic through Tor.],
    [BlackArch], [Arch], [Advanced pentesting], [Built on Arch, with a huge set of over 2800 tools. Meant for experienced testers who want the newest tools.],
    [CAINE], [Ubuntu], [Digital forensics], [Made for investigations. Opens evidence drives as read-only by default so nothing on them changes, and comes with a full forensic toolkit.],
    [Tails], [Debian], [Privacy], [A live system that forgets everything. All traffic goes through Tor, and nothing is left on the computer once it shuts down.],
    [Whonix], [Debian], [Privacy], [Splits into two virtual machines, a gateway and a workstation. Everything goes through Tor, so the real IP address stays hidden.],
    [Qubes OS], [Xen / Fedora], [Isolation], [Keeps each task in its own virtual machine, so if one gets infected the rest stay safe.],
    [Security Onion], [Ubuntu], [Monitoring], [A network-watching platform. Bundles Suricata, Zeek, Wazuh, and Elastic to spot intrusions and hunt for threats.],
  ),
  caption: [Linux distributions used in a cybersecurity lab.],
)

== Recommended distribution for each role

/ Penetration testing: Kali Linux is the usual pick, since it comes ready with
  almost every tool and has plenty of guides. Parrot suits someone who also wants
  privacy tools and a lighter desktop, and BlackArch is for experienced testers who
  want the biggest tool set.

/ Digital forensics: CAINE fits best. It opens evidence read-only and keeps the
  whole investigation repeatable, which matters when the findings have to stand up
  as proof.

/ Privacy: Tails is best for a quick, throwaway session that leaves nothing behind.
  Whonix is better when the same anonymous setup is needed again and again, and
  Qubes OS suits someone who wants to keep many tasks walled off on one machine.

/ Security monitoring: Security Onion is made for this. Intrusion detection, log
  analysis, and threat hunting are all set up and ready.

#pagebreak()

== Selection guide

#figure(
  table(
    columns: (1.4fr, 1fr),
    [*Task*], [*Recommended distribution*],
    [Test a target for weaknesses], [Kali (or Parrot, BlackArch)],
    [Examine a disk image or seized drive], [CAINE],
    [Work anonymously with no trace left], [Tails],
    [Keep a permanent anonymous workstation], [Whonix],
    [Separate risky work on one machine], [Qubes OS],
    [Watch the network for intrusions], [Security Onion],
  ),
  caption: [A quick guide from the task to the distribution.],
)

In a real lab these run on separate machines: Kali or Parrot for testing, CAINE for
forensics, Tails or Whonix for anonymous work, and Security Onion for watching the
network. Keeping them apart makes sure evidence, attack tools, and monitoring never
get mixed up.

= Exit Status

== What an exit status is

When a Linux command finishes, it leaves behind a small number called the exit
status. Zero means it worked, and anything else means it ran into trouble. The shell
remembers the last one in a variable called `$?`, which is read with `echo $?`. For
example, listing a file that exists gives 0, and listing one that is missing gives 2.

== Command #sym.arrow result #sym.arrow exit status #sym.arrow meaning

#figure(
  table(
    columns: (auto, 1.1fr, auto, 1.3fr),
    [*Command*], [*Result*], [*`$?`*], [*Meaning*],
    [`ls /etc/hostname`], [File listed], [`0`], [It worked],
    [`ls /no/such/path`], [Path missing], [`2`], [`ls` hit a real problem],
    [`grep root /etc/passwd`], [Match printed], [`0`], [Found a match],
    [`grep zzzz /etc/passwd`], [No output], [`1`], [Ran fine, but found nothing],
    [`grep x /no/file`], [Error message], [`2`], [The file is not there],
    [`mkdir /a/b/c`], [Cannot create], [`1`], [The parent folders are missing],
    [`foobar123`], [Refused], [`127`], [No such command],
  ),
  caption: [A few commands that work and a few that fail, with the status each returns.],
)

So failure is not a single thing. The `grep` command gives 1 when it finds nothing
but 2 when the file is missing, which lets whatever called it treat the two cases
differently.

#pagebreak()

== Common exit codes

#figure(
  table(
    columns: (auto, 1fr),
    [*Code*], [*Meaning*],
    [`0`], [The command worked.],
    [`1`], [Something went wrong. This is the usual "it failed" code.],
    [`2`], [The command was used the wrong way, like a bad option or a file that is not there.],
    [`126`], [The file is there, but it has no permission to run.],
    [`127`], [The command was not found, usually a spelling mistake.],
    [`128 + N`], [The command was stopped by a signal. Pressing Ctrl-C gives 130.],
  ),
  caption: [The exit codes seen most often and what each one usually means.],
)

== What a script learns from an exit status

A script leans on the exit status to know whether the last command worked, and then
it decides what to do next.

- It checks whether the last step passed or failed. With `&&` the next command runs
  only if the first one worked, and with `||` it runs only if the first one failed.
- It tells one failure from another. From `grep`, a 1 means nothing was found, a 2
  means the command was broken, and a 127 means a program it needs is missing.
- It decides what happens next. Depending on the status it stops, tries again, or
  reports the error, and then hands its own status up to whatever called it.

Without the exit status a script is working blind. With it, the script knows what
happened and reacts the right way.
