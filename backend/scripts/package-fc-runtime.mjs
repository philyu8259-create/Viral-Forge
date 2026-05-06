import { cp, mkdir, rm, stat, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const distDir = join(root, "dist");
const stagingDir = join(distDir, "fc-runtime");
const outputZip = join(distDir, "viralforge-fc-runtime.zip");

await assertExists(join(root, "node_modules"), "node_modules is missing. Run npm install before packaging.");
await rm(stagingDir, { recursive: true, force: true });
await rm(outputZip, { force: true });
await mkdir(stagingDir, { recursive: true });

await Promise.all([
  cp(join(root, "src"), join(stagingDir, "src"), { recursive: true }),
  cp(join(root, "node_modules"), join(stagingDir, "node_modules"), { recursive: true }),
  cp(join(root, "package.json"), join(stagingDir, "package.json")),
  cp(join(root, "package-lock.json"), join(stagingDir, "package-lock.json"))
]);

await writeFile(join(stagingDir, "index.mjs"), "export { handler } from './src/fc-handler.mjs';\n");

const bootstrap = `#!/usr/bin/env bash
set -euo pipefail
export PORT="\${PORT:-\${CAPort:-8787}}"
exec node src/main.mjs
`;

const bootstrapPath = join(stagingDir, "bootstrap");
await writeFile(bootstrapPath, bootstrap, { mode: 0o755 });

await run("zip", ["-qr", outputZip, "."], { cwd: stagingDir });
console.log(outputZip);

async function assertExists(path, message) {
  try {
    await stat(path);
  } catch {
    throw new Error(message);
  }
}

function run(command, args, options = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, {
      ...options,
      stdio: ["ignore", "inherit", "inherit"]
    });
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) {
        resolvePromise();
      } else {
        reject(new Error(`${command} exited with code ${code}`));
      }
    });
  });
}
