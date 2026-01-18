import { execSync } from "child_process";

execSync("ssh oneplus-gm1901", { stdio: "inherit", shell: true });
