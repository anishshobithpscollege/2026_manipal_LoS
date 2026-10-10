#!/usr/bin/env python3
"""Generate a synthetic OpenSSH auth.log for the Theory 06 assignment.

Everything here is invented. Hostnames, users and addresses are made up, and the
public-looking addresses come from the RFC 5737 documentation ranges
(192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24) so they cannot belong to a real
host. No system was scanned or attacked. The output imitates the format of
/var/log/auth.log on Debian/Ubuntu. A fixed seed makes the file reproducible.
"""
import random
from datetime import datetime, timedelta

random.seed(2026)
HOST = "labhost"
events = []  # (datetime, line-body-after-host)
pid = [1000]


def next_pid():
    pid[0] += random.randint(1, 9)
    return pid[0]


def add(t, text):
    events.append((t, text))


def sshd(t, msg, p=None):
    add(t, f"sshd[{p or next_pid()}]: {msg}")


def fail(t, user, ip, valid):
    p = next_pid()
    if not valid:
        sshd(t, f"Invalid user {user} from {ip} port {random.randint(30000, 60000)}", p)
    kind = "" if valid else "invalid user "
    sshd(t, f"Failed password for {kind}{user} from {ip} port {random.randint(30000, 60000)} ssh2", p)


def accept(t, user, ip, method="password", uid=1000):
    p = next_pid()
    sshd(t, f"Accepted {method} for {user} from {ip} port {random.randint(30000, 60000)} ssh2", p)
    add(t, f"sshd[{p}]: pam_unix(sshd:session): session opened for user {user}(uid={uid}) by (uid=0)")
    end = t + timedelta(minutes=random.randint(3, 90))
    add(end, f"sshd[{p}]: pam_unix(sshd:session): session closed for user {user}")


def sudo(t, user, cmd):
    add(t, f"sudo: {user:>8} : TTY=pts/0 ; PWD=/home/{user} ; USER=root ; COMMAND={cmd}")


USERS = {"alice": 1001, "bob": 1002, "carol": 1003, "deploy": 1004, "root": 0}
day = datetime(2026, 10, 7)

# --- benign baseline: staff log in from the internal 10.0.0.0/24 network ----
for d in range(2):
    base = day + timedelta(days=d)
    for user, uid in USERS.items():
        if user == "root":
            continue
        for _ in range(random.randint(2, 4)):
            t = base + timedelta(hours=random.randint(8, 18), minutes=random.randint(0, 59),
                                 seconds=random.randint(0, 59))
            ip = f"10.0.0.{random.randint(10, 40)}"
            if random.random() < 0.3:
                fail(t - timedelta(seconds=20), user, ip, True)
            accept(t, user, ip, random.choice(["publickey", "publickey", "password"]), uid)

# bob forgets his password after a holiday: 4 failures then success (false positive)
t = day + timedelta(days=1, hours=9, minutes=2)
for i in range(4):
    fail(t + timedelta(seconds=i * 11), "bob", "10.0.0.23", True)
accept(t + timedelta(seconds=60), "bob", "10.0.0.23", "password", 1002)

# carol works late from her internal desk (off-hours but internal)
accept(day + timedelta(hours=22, minutes=30), "carol", "10.0.0.31", "publickey", 1003)

# office NAT gateway: many people mistype over two days (slow, spread out)
for i in range(12):
    t = day + timedelta(hours=9 + i * 3 + random.randint(0, 1), minutes=random.randint(0, 59))
    fail(t, random.choice(["alice", "bob", "carol", "intern1"]), "192.0.2.10",
         random.random() < 0.7)

# --- internet background noise: one or two probes per address -----------------
for i in range(100, 124):
    ip = f"203.0.113.{i}"
    t = day + timedelta(hours=random.randint(0, 47), minutes=random.randint(0, 59),
                        seconds=random.randint(0, 59))
    for _ in range(random.randint(1, 2)):
        fail(t, random.choice(["admin", "test", "guest", "oracle"]), ip, False)
        t += timedelta(seconds=random.randint(2, 6))
    sshd(t, f"Connection closed by authenticating user {ip} port 40000 [preauth]")
for i in range(5):
    t = day + timedelta(hours=random.randint(0, 47), minutes=random.randint(0, 59))
    sshd(t, f"Did not receive identification string from 203.0.113.{130 + i} port 52000")

# --- incident 1: brute force from 203.0.113.45, then a successful login -------
attacker = "203.0.113.45"
dictionary = ["root", "admin", "test", "oracle", "ubuntu", "postgres", "user", "ftp",
              "git", "pi", "deploy", "mysql", "guest", "support"]
t = day + timedelta(hours=2, minutes=14)
for _ in range(420):
    u = random.choice(dictionary)
    fail(t, u, attacker, u in ("root", "deploy"))
    t += timedelta(seconds=random.randint(1, 3))
t += timedelta(seconds=7)
accept(t, "deploy", attacker, "password", 1004)
sudo(t + timedelta(seconds=40), "deploy", "/usr/bin/cat /etc/shadow")
sudo(t + timedelta(seconds=95), "deploy", "/usr/sbin/useradd -m svc_backup")
sudo(t + timedelta(seconds=130), "deploy", "/usr/bin/systemctl restart sshd")

# --- incident 2: slow password spray from 198.51.100.77 ------------------------
spray = "198.51.100.77"
names = ["alice", "bob", "carol", "deploy", "root", "admin", "jenkins", "backup",
         "dev", "web", "mail", "ops"]
t = day + timedelta(hours=13)
for rnd in range(2):
    for u in names:
        fail(t, u, spray, u in USERS)
        t += timedelta(minutes=random.randint(8, 14))

# --- incident 3: off-hours login from an unfamiliar external address -----------
t = day + timedelta(days=1, hours=3, minutes=41, seconds=9)
accept(t, "alice", "192.0.2.88", "publickey", 1001)
sudo(t + timedelta(seconds=25), "alice", "/usr/bin/tar czf /tmp/home.tgz /home")
sudo(t + timedelta(seconds=80), "alice", "/usr/bin/apt update")

events.sort(key=lambda e: e[0])
with open("auth.log", "w") as f:
    for t, text in events:
        stamp = f"{t.strftime('%b')} {t.day:>2} {t.strftime('%H:%M:%S')}"
        f.write(f"{stamp} {HOST} {text}\n")
print(len(events), "lines written to auth.log")
