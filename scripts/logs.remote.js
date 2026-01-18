import { execSync } from "child_process";

execSync(
  "ssh oneplus-gm1901 'bash -lc \"tail -f ~/services/voicesewa_backend/logs/backend.log\"'",
    { stdio: "inherit", shell: true }
);
