# DeepSeek Balance for Codex

一个用于实时查询 DeepSeek API 余额的本地 Codex 插件，附带可选的 Windows
置顶余额小窗。

这个项目解决两个实际问题：

- 在 Codex 中快速查询 DeepSeek 总余额、赠金余额和充值余额。
- 在桌面右上角常驻显示余额，定时自动刷新，不需要反复向 AI 提问。

> 非官方项目，与 DeepSeek、OpenAI 均无隶属关系。

## 功能

- 查询 DeepSeek 官方余额接口：`GET https://api.deepseek.com/user/balance`
- 展示人民币和美元账户余额
- 分别展示赠金余额和充值余额
- 提供官方充值入口
- 支持 Codex 插件主页入口和默认提示词
- 提供 Windows 置顶小窗，默认每 60 秒刷新
- API 密钥不会写入插件源码或仓库

## 项目结构

```text
.
├── .agents/plugins/marketplace.json   # 本地 Codex 插件市场
├── plugins/deepseek-balance/          # Codex 插件
│   ├── .codex-plugin/plugin.json
│   ├── assets/
│   ├── scripts/deepseek_balance.mjs
│   └── skills/deepseek-balance/SKILL.md
├── widget/                            # Windows 置顶余额小窗
└── test/                              # 无网络冒烟测试
```

## 安装 Codex 插件

要求：

- 支持本地插件市场的 Codex 版本
- Node.js 18 或更高版本

克隆仓库后，在仓库根目录执行：

```bash
codex plugin marketplace add .
codex plugin add deepseek-balance@local-deepseek
```

完整退出并重新打开 Codex。进入左侧 `Plugins` 应能看到
`DeepSeek 余额`。

默认提示词：

```text
查看我的 DeepSeek 余额
```

## 配置 API 密钥

插件按以下顺序读取密钥：

1. 环境变量 `DEEPSEEK_API_KEY`
2. `%USERPROFILE%\.codex\deepseek-balance.json`
3. 当 Codex 当前模型提供方指向 `https://api.deepseek.com` 时，读取现有
   `%USERPROFILE%\.codex\auth.json`

推荐使用独立配置文件：

```json
{
  "apiKey": "sk-..."
}
```

保存到：

```text
%USERPROFILE%\.codex\deepseek-balance.json
```

不要提交 `auth.json`、`deepseek-balance.json` 或任何真实 API 密钥。

## 使用置顶小窗

要求：

- Windows
- PowerShell 7

启动：

```powershell
pwsh -Sta -NoProfile -ExecutionPolicy Bypass -File .\widget\DeepSeekBalanceWidget.ps1
```

小窗默认固定在桌面右上角，支持拖动、手动刷新、自动刷新和跳转充值页。

## Codex 平台限制

Codex 插件主页目前支持插件入口和默认提示词，但不支持在主页卡片中嵌入
任意、自动刷新的实时数字。因此：

- 插件提供“点开即查询”的原生入口。
- Windows 小窗提供持续可见和自动刷新的体验。

本项目不会用静态数字伪装成实时余额。

## 安全说明

- 查询过程只在用户本机发起。
- 插件只向 `api.deepseek.com` 发送 API 密钥。
- 密钥不写入日志、插件目录或 Git 仓库。
- 充值按钮只打开 DeepSeek 官方充值页。

## 开发与测试

运行无网络测试：

```bash
node test/manifest.mjs
node --check plugins/deepseek-balance/scripts/deepseek_balance.mjs
```

## License

[MIT](LICENSE)
