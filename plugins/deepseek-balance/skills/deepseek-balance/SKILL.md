---
name: "deepseek-balance"
description: "Check the live DeepSeek API account balance and provide the official top-up link. Use when the user asks about DeepSeek balance, remaining credit, billing, or topping up DeepSeek."
---

# DeepSeek Balance

Run the bundled balance checker:

```bash
node "<plugin-root>/scripts/deepseek_balance.mjs"
```

Resolve `<plugin-root>` relative to this `SKILL.md` file. Do not print the API key or include it in commands, logs, or files.

The script reads the key in this order:

1. `DEEPSEEK_API_KEY`
2. `$CODEX_HOME/deepseek-balance.json` with an `apiKey` field
3. `$CODEX_HOME/auth.json` when the configured custom provider base URL is `https://api.deepseek.com`

Present the result compactly:

- Total balance for each returned currency
- Granted balance
- Topped-up balance
- Whether the account is available
- Official top-up link: `https://platform.deepseek.com/top_up`

If the request fails, report the HTTP status and a short error message. For authentication failures, tell the user to set `DEEPSEEK_API_KEY` or create `%USERPROFILE%\.codex\deepseek-balance.json`:

```json
{"apiKey":"sk-..."}
```

Do not write the key into this plugin directory.
