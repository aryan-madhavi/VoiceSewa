import { execSync } from "child_process";
import fs from "fs";
import os from "os";
import path from "path";

const HOST = "oneplus-gm1901";
const IP = "100.83.124.11";
const USER = "u0_a459";
const PORT = "8022";

function fail(msg) {
  console.error(`[remote-preflight] DEV ENV NOT SET: ${msg}\n`);
  process.exit(1);
}

function run(cmd) {
  return execSync(cmd, { stdio: "ignore", shell: true });
}

/* 1. Check Tailscale */
try {
  run("tailscale status");
} catch {
  fail("Tailscale not installed or not running.");
}

/* 2. Check device presence (cross-platform) */
try {
  const status = execSync("tailscale status", { encoding: "utf8", shell: true });
  if (!status.includes(HOST)) {
    fail(`${HOST} not found in Tailscale. Ask key from backend handler.`);
  }
} catch {
  fail(`${HOST} not found in Tailscale. Ask key from backend handler.`);
}

/* 3. Ensure SSH config */
const sshDir = path.join(os.homedir(), ".ssh");
const configPath = path.join(sshDir, "config");

if (!fs.existsSync(sshDir)) fs.mkdirSync(sshDir, { recursive: true });

let config = fs.existsSync(configPath) 
? fs.readFileSync(configPath, "utf8") 
: "";

if (!config.includes(`Host ${HOST}`)) {
  fs.appendFileSync(
    configPath,
    `\nHost ${HOST}\n  HostName ${IP}\n  User ${USER}\n  Port ${PORT}\n`
  );
  try { 
    fs.chmodSync(sshDir, 0o700)
    fs.chmodSync(configPath, 0o600); 
  } catch {} // ignore on Windows
  console.log(`[remote-preflight] SSH config for ${HOST} created.\n`);
}

/* 4. Test SSH */
try {
  run(`ssh -o ConnectTimeout=5 ${HOST} "echo connected\n"`);
} catch {
  fail(`Cannot SSH into ${HOST}. Ask key from backend handler.\n`);
}

console.log("[remote-preflight] Environment checks passed.\n");
