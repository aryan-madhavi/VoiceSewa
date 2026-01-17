# VoiceSewa – Android Phone as Remote Dev Backend (Termux + Tailscale)

This document summarizes **everything that was set up** to run and manage a Node.js backend on an **Android phone** for **development purposes**, controlled remotely from a **laptop** over **Tailscale + SSH**.

The phone acts as a **remote dev target**, not a production server.

---

## 0. TL;DR

### 0.1 Activate dev environment

Depending on your shell:

| Shell / OS                         | Command to activate             |
| ---------------------------------- | ------------------------------- |
| **POSIX (Linux / macOS / Termux)** | `source ./scripts/activate-dev` |
| **Windows PowerShell**             | `.\scripts\activate-dev.ps1`    |
| **Windows CMD**                    | `activate-dev.cmd`              |

* **Pre-requisites:**

  * Tailscale installed and running; `oneplus-gm1901` must appear in `tailscale status`.
  * Your SSH key is authorized on the phone (`~/.ssh/authorized_keys`).

### 0.2 Available aliases / functions after activation

| Command          | Description                            |
| ---------------- | -------------------------------------- |
| `ssh-phone`      | SSH into the device (`oneplus-gm1901`) |
| `deploy-backend` | Deploy and restart backend via SSH     |
| `backend-status` | Check backend status via cURL          |
| `stop-backend`   | Stop backend via SSH                   |
| `view-logs`      | Tail backend logs via SSH              |
| `deactivate-dev` | Deactivate the dev environment         |

> If activation fails (Tailscale missing, host unreachable, or SSH key missing), the environment will **not be set**, and you will see a message like:
> `[activate-dev] DEV ENV NOT SET: Cannot SSH into oneplus-gm1901. Ask key from backend handler.`


---

## 1. High-level architecture

* Backend code lives in a **Git repository**
* Laptop and phone are connected via **Tailscale**
* **Tailscale runs as an Android app**, not inside Termux
* **Termux** provides:

  * Node.js runtime
  * Git
  * SSH server
  * tmux for process lifecycle
* Backend is started/stopped/redeployed **remotely from the laptop**
* No system services, no runit, no systemd

```
Laptop
  └── SSH over Tailscale
        └── Termux (Android)
              ├── git pull
              ├── npm install
              ├── tmux-managed Node process
              └── file-based logs
```

---

## 2. Phone-side setup (Termux)

### Installed packages

```sh
pkg install git nodejs openssh tmux
```

### SSH server

* SSH runs **inside Termux**
* Default port: **8022**
* Must be started at boot via Termux:Boot

`~/.termux/boot/start-ssh`:

```sh
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
```

> Sometimes you may need to start Termux manually if Android kills the app or device restarts. Termux:Boot ensures SSH starts automatically when the device boots.

---

## 3. Tailscale setup

* Tailscale installed as a **native Android app**
* Termux automatically uses the phone’s network
* No Tailscale installation inside Termux

Phone Tailscale IP:

```sh
tailscale ip
```

Example:

```
100.83.124.11
```

---

## 4. SSH configuration (Laptop)

`activate-dev` automatically ensures SSH config exists:

```ssh
Host oneplus-gm1901
  HostName 100.83.124.11
  User u0_a459
  Port 8022
```

SSH works as:

```sh
ssh-phone
```

> You no longer need to manually manage the IP or port; `activate-dev` sets up the aliases.

### SSH authentication

* Initially password-based (`passwd: abc123`)
* Then switch to SSH keys:

```sh
ssh-keygen
ssh-copy-id oneplus-gm1901
```

---

## 5. Directory layout on the phone

```
~/services/voicesewa_backend/
├── src/                  # Git repo (Node backend)
├── logs/
│   └── backend.log
├── keys/
│   └── ServiceAccountKey.json
├── sync-backend.sh
├── deploy-and-restart.sh
└── stop-backend.sh
```

All files live in **user space**, not system directories.

---

## 6. Backend sync script (phone)

`sync-backend.sh`

* Shallow clone (`--depth 1`)
* Hard reset to remote branch
* Always reflects latest Git state

Purpose: keep phone backend in sync with Git repo.

---

## 7. Deploy + restart script (phone)

`deploy-and-restart.sh`

What it does:

1. Pull latest backend code
2. Copy `ServiceAccountKey.json` into backend
3. Run `npm install`
4. Restart backend inside a tmux session
5. Pipe logs to a persistent file

Backend is started as:

```
tmux session: voicesewa
log file: logs/backend.log
```

---

## 8. Stop backend script (phone)

`stop-backend.sh`

* Stops backend by killing the tmux session
* Clean, deterministic shutdown
* No port scanning required

---

## 9. Laptop-side usage (via `activate-dev`)

Once `activate-dev` is sourced:

### Deploy from laptop

```sh
deploy-backend
```

### Stop backend from laptop

```sh
stop-backend
```

### View logs

```sh
view-logs
```

### SSH into the phone

```sh
ssh-phone
```

### Deactivate dev environment

```sh
deactivate-dev
```

> `activate-dev` ensures SSH is reachable, Tailscale is running, and aliases/functions are set up. If any prerequisite fails, the environment will **not be set**, and a warning is printed.

---

## 10. Copy secrets from laptop to phone

`ServiceAccountKey.json` is copied via SCP:

```sh
scp path/to/ServiceAccountKey.json \
    oneplus-gm1901:~/services/voicesewa_backend/keys/
```

SSH config alias removes the need for IP/port flags.

---

## 11. Logging strategy

* No logging daemons
* No system logging services
* Node logs to stdout/stderr
* Logs captured via `tee`

Log location:

```
~/services/voicesewa_backend/logs/backend.log
```

View logs locally:

```sh
tail -f logs/backend.log
```

Or remotely:

```sh
view-logs
```

---

## 12. Port cleanup (if needed)

To force-stop any process on port 3000:

```sh
lsof -ti tcp:3000 | xargs -r kill
```

Preferred approach: stop backend via `stop-backend`.

---

## 13. Why this design

### Used

* Termux
* tmux
* Git
* SSH
* Tailscale

### Explicitly avoided

* runit / sv
* systemd
* background Android services
* Docker
* syslog / journald

Reason: Android does not support a real service model; user-space process control is reliable and predictable. This setup matches Android’s lifecycle constraints.

---

## 14. Intended use case

* Development backend
* API testing
* Bots
* LAN / Tailscale access
* Manual or scripted redeploys

Not intended for:

* Production
* 24/7 uptime guarantees
* Auto-start after Android process death

---

## 15. Summary

This setup provides:

* Remote-controlled dev backend
* Deterministic deploys
* Clean restarts
* Persistent logs
* Minimal complexity
* Android-native behavior

The phone is treated as a **remote dev machine**, not a server OS.

---

I can also make a **diagram showing aliases → commands → phone** to make onboarding even faster. It would be a nice visual TL;DR.

Do you want me to create that diagram?
