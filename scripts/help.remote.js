console.log(`
Manage remote backend: deploy, stop, logs, ssh, etc.

Usage:
  npm run remote:<command>

Available Modules:
  remote:preflight          Check Tailscale, SSH, and environment
  remote:ssh                Open SSH shell on remote backend
  remote:deploy             Sync code, install deps, start/restart backend
  remote:stop               Stop backend tmux session
  remote:logs               Tail backend logs in real-time
  remote:status             Show if backend is RUNNING or STOPPED
  remote:help               Show this help message
`);
