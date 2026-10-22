import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const marketplacePath = path.join(
  root,
  ".agents",
  "plugins",
  "marketplace.json",
);
const pluginPath = path.join(
  root,
  "plugins",
  "deepseek-balance",
  ".codex-plugin",
  "plugin.json",
);

const marketplace = JSON.parse(await fs.readFile(marketplacePath, "utf8"));
const plugin = JSON.parse(await fs.readFile(pluginPath, "utf8"));

assert.equal(marketplace.name, "local-deepseek");
assert.equal(marketplace.plugins[0].name, "deepseek-balance");
assert.equal(plugin.name, "deepseek-balance");
assert.match(plugin.version, /^\d+\.\d+\.\d+$/);
assert.equal(plugin.interface.displayName, "DeepSeek 余额");

for (const asset of ["composerIcon", "logo"]) {
  const assetPath = path.join(
    root,
    "plugins",
    "deepseek-balance",
    plugin.interface[asset],
  );
  const stat = await fs.stat(assetPath);
  assert.ok(stat.size > 0, `${asset} must not be empty`);
}

console.log("Manifest and assets are valid.");
