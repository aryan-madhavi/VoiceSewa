import { execSync } from "child_process";

const action = process.argv[2];
if (!action) {
  console.error("[run-remote] No action specified.");
  process.exit(1);
}

try {
  execSync("node scripts/preflight.remote.js", { stdio: "inherit", shell: true });
  execSync(`node scripts/${action}.remote.js`, { stdio: "inherit", shell: true });
} catch (err) {
  process.exit(err.status ?? 1);
}
