# DeepSeek Balance Widget

Always-on-top Windows widget that refreshes the live DeepSeek API balance every
60 seconds. It reuses the local Codex DeepSeek credentials and never stores the
API key in this folder.

Start it with:

```powershell
pwsh -Sta -NoProfile -ExecutionPolicy Bypass -File .\DeepSeekBalanceWidget.ps1
```

See the repository [README](../README.md) for credential configuration and
security notes.
