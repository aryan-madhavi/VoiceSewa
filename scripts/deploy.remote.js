import { execSync } from "child_process";

const URL = "http://oneplus-gm1901.orthrus-mahi.ts.net:3000/api";

execSync(
  'ssh oneplus-gm1901 "bash -lc \'cd ~/services/voicesewa_backend && ./deploy-and-restart.sh\'"',
  { stdio: "inherit", shell: true }
);

console.log(`[remote-deploy] Deploy command completed (${URL})`);
