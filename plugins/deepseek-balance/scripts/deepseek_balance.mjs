#!/usr/bin/env node

import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const CODEX_HOME =
  process.env.CODEX_HOME?.trim() || path.join(os.homedir(), ".codex");
const BALANCE_URL = "https://api.deepseek.com/user/balance";
const TOP_UP_URL = "https://platform.deepseek.com/top_up";

async function readText(filePath) {
  try {
    return await fs.readFile(filePath, "utf8");
  } catch {
    return null;
  }
}

async function readJson(filePath) {
  const text = await readText(filePath);
  if (!text) return null;

  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

async function resolveApiKey() {
  const explicitKey = process.env.DEEPSEEK_API_KEY?.trim();
  if (explicitKey) {
    return { key: explicitKey, source: "DEEPSEEK_API_KEY" };
  }

  const localConfig = await readJson(
    path.join(CODEX_HOME, "deepseek-balance.json"),
  );
  if (typeof localConfig?.apiKey === "string" && localConfig.apiKey.trim()) {
    return { key: localConfig.apiKey.trim(), source: "local-config" };
  }

  const codexConfig = await readText(path.join(CODEX_HOME, "config.toml"));
  const usesDeepSeekProvider =
    typeof codexConfig === "string" &&
    /base_url\s*=\s*["']https:\/\/api\.deepseek\.com\/?["']/i.test(
      codexConfig,
    );

  if (usesDeepSeekProvider) {
    const auth = await readJson(path.join(CODEX_HOME, "auth.json"));
    if (typeof auth?.OPENAI_API_KEY === "string" && auth.OPENAI_API_KEY.trim()) {
      return { key: auth.OPENAI_API_KEY.trim(), source: "codex-auth" };
    }
  }

  throw new Error(
    "DEEPSEEK_API_KEY is not configured. Set it in the environment, or create " +
      path.join(CODEX_HOME, "deepseek-balance.json") +
      ' with {"apiKey":"sk-..."}.',
  );
}

function formatMoney(value, currency) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return String(value ?? "-");

  const formatted = numeric.toLocaleString("zh-CN", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

  return currency === "CNY" ? `¥${formatted}` : `${formatted} ${currency}`;
}

async function main() {
  const { key, source } = await resolveApiKey();
  const response = await fetch(BALANCE_URL, {
    method: "GET",
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${key}`,
    },
    signal: AbortSignal.timeout(15_000),
  });

  const bodyText = await response.text();
  let body;
  try {
    body = JSON.parse(bodyText);
  } catch {
    body = { raw: bodyText.slice(0, 500) };
  }

  if (!response.ok) {
    console.error(
      JSON.stringify(
        {
          ok: false,
          status: response.status,
          error: body?.error?.message || body?.message || body?.raw || "Request failed",
          keySource: source,
        },
        null,
        2,
      ),
    );
    process.exitCode = 1;
    return;
  }

  const balances = Array.isArray(body?.balance_infos)
    ? body.balance_infos.map((balance) => ({
        currency: balance.currency || "CNY",
        totalBalance: formatMoney(balance.total_balance, balance.currency),
        grantedBalance: formatMoney(
          balance.granted_balance,
          balance.currency,
        ),
        toppedUpBalance: formatMoney(
          balance.topped_up_balance,
          balance.currency,
        ),
      }))
    : [];

  console.log(
    JSON.stringify(
      {
        ok: true,
        available: body?.is_available === true,
        balances,
        checkedAt: new Date().toISOString(),
        topUpUrl: TOP_UP_URL,
        keySource: source,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(
    JSON.stringify(
      {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      },
      null,
      2,
    ),
  );
  process.exitCode = 1;
});
