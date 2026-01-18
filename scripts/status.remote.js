import { execSync } from "child_process";

try {
  execSync(
    'ssh oneplus-gm1901 "bash -lc \'cd ~/services/voicesewa_backend && ./status-backend.sh\'"',
    { stdio: "inherit", shell: true }
  );
} catch {
  process.exit(1);
}