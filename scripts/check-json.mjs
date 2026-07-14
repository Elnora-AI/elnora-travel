#!/usr/bin/env node
// Validate the plugin manifests parse and carry the required fields, and that
// no populated per-user config leaked into the repo.

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const errors = [];

function loadJson(rel) {
  const path = join(ROOT, rel);
  if (!existsSync(path)) {
    errors.push(`${rel}: missing`);
    return null;
  }
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (err) {
    errors.push(`${rel}: invalid JSON (${err.message})`);
    return null;
  }
}

const plugin = loadJson(".claude-plugin/plugin.json");
if (plugin) {
  for (const key of ["name", "version", "description", "author"]) {
    if (!plugin[key]) errors.push(`.claude-plugin/plugin.json: missing "${key}"`);
  }
  if (plugin.name !== "travel-planning") {
    errors.push(`.claude-plugin/plugin.json: name must be "travel-planning"`);
  }
  const servers = plugin.mcpServers || {};
  if (!servers.airbnb) {
    errors.push(".claude-plugin/plugin.json: missing mcpServers.airbnb");
  } else {
    const pkg = (servers.airbnb.args || []).find((a) => a.startsWith("@openbnb/mcp-server-airbnb"));
    if (!pkg || !/@\d+\.\d+\.\d+$/.test(pkg)) {
      errors.push(".claude-plugin/plugin.json: mcpServers.airbnb must pin an exact @openbnb/mcp-server-airbnb version");
    }
  }
  for (const [name, server] of Object.entries(servers)) {
    for (const val of Object.values(server.env || {})) {
      if (!/^\$\{[A-Z0-9_]+\}$/.test(val)) {
        errors.push(`.claude-plugin/plugin.json: mcpServers.${name} env values must be \${VAR} references — never real keys`);
      }
    }
  }
}

const market = loadJson(".claude-plugin/marketplace.json");
if (market) {
  if (!Array.isArray(market.plugins) || market.plugins.length === 0) {
    errors.push(".claude-plugin/marketplace.json: plugins[] must be non-empty");
  } else {
    const p = market.plugins[0];
    if (p.name !== "travel-planning") errors.push("marketplace.json: plugin name must be travel-planning");
    if (p.source !== "./") errors.push('marketplace.json: plugin source must be "./"');
    if (plugin && p.version !== plugin.version) {
      errors.push(`marketplace.json: version ${p.version} != plugin.json version ${plugin.version}`);
    }
  }
}

// A populated per-user config must never be committed.
for (const leak of ["travel-preferences.local.md", ".config/travel-planning/env"]) {
  if (existsSync(join(ROOT, leak))) errors.push(`${leak}: per-user config must not be committed`);
}

if (errors.length > 0) {
  console.error("Manifest validation failed:\n");
  for (const e of errors) console.error(`  - ${e}`);
  process.exit(1);
}
console.log("check-json: manifests valid, no leaked config.");
