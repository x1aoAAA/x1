# Security Policy

Please do not open a public issue for credential leaks or other security
problems.

## Credential handling

- The plugin never stores the DeepSeek API key inside the repository.
- The key is read from `DEEPSEEK_API_KEY`, a local Codex config file, or the
  existing Codex DeepSeek provider credential.
- Do not commit `auth.json`, `deepseek-balance.json`, `.env`, shell history, or
  screenshots containing credentials.
- If a key is exposed, revoke it immediately in the DeepSeek console.

## Network access

The plugin only calls `https://api.deepseek.com/user/balance`. The top-up
button only opens `https://platform.deepseek.com/top_up`.
