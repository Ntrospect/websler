# Ops note — Fail2Ban on chat.jumoki.com (Nov 2, 2025)

**What we changed**
- Created `/etc/fail2ban/jail.d/10-sshd.conf` with a single `sshd` jail.
- Using file/polling backend and `/var/log/auth.log` (not systemd journal).
- Fixed date parsing with Fail2Ban token syntax.

**/etc/fail2ban/jail.d/10-sshd.conf**
[sshd]
enabled   = true
backend   = polling
logpath   = /var/log/auth.log
port      = ssh
maxretry  = 5
findtime  = 10m
bantime   = 1h
banaction = ufw
datepattern = ^{^LN-BEG}MON Day 24hour:Minute:Second

**Verified**
- `sudo systemctl status fail2ban` → active
- `sudo fail2ban-client status` → shows 1 jail (`sshd`)
- `sudo fail2ban-client status sshd` → watching `/var/log/auth.log`
- `sudo ufw status numbered` → allow rules in place; bans will appear as UFW denies

**Notes**
- We avoided the `systemd` backend because `python3-systemd`/journald binding wasn’t usable; file backend is stable.
- If you later switch to journald, set `backend=systemd` and remove the custom `logpath`/`datepattern`.
- Occasional “timezone deviation” warnings are harmless unless timestamps are truly off.
