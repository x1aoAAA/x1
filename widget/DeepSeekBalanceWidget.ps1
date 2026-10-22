param(
    [int]$RefreshSeconds = 60
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$topUpUrl = "https://platform.deepseek.com/top_up"
$codexHome = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $HOME ".codex"
}

function Get-DeepSeekApiKey {
    if ($env:DEEPSEEK_API_KEY) {
        return $env:DEEPSEEK_API_KEY.Trim()
    }

    $localConfigPath = Join-Path $codexHome "deepseek-balance.json"
    if (Test-Path -LiteralPath $localConfigPath) {
        $localConfig = Get-Content -LiteralPath $localConfigPath -Raw |
            ConvertFrom-Json
        if ($localConfig.apiKey) {
            return [string]$localConfig.apiKey
        }
    }

    $configPath = Join-Path $codexHome "config.toml"
    $config = if (Test-Path -LiteralPath $configPath) {
        Get-Content -LiteralPath $configPath -Raw
    } else {
        ""
    }

    if ($config -notmatch 'base_url\s*=\s*["'']https://api\.deepseek\.com/?["'']') {
        throw "当前 Codex 配置不是 DeepSeek 提供方，请设置 DEEPSEEK_API_KEY。"
    }

    $authPath = Join-Path $codexHome "auth.json"
    if (-not (Test-Path -LiteralPath $authPath)) {
        throw "没有找到 Codex 登录凭据，请设置 DEEPSEEK_API_KEY。"
    }

    $auth = Get-Content -LiteralPath $authPath -Raw | ConvertFrom-Json
    if (-not $auth.OPENAI_API_KEY) {
        throw "Codex 凭据中没有可用的 DeepSeek 密钥。"
    }

    return [string]$auth.OPENAI_API_KEY
}

function Get-DeepSeekBalance {
    $apiKey = Get-DeepSeekApiKey
    $headers = @{
        Accept        = "application/json"
        Authorization = "Bearer $apiKey"
    }

    $response = Invoke-RestMethod `
        -Uri "https://api.deepseek.com/user/balance" `
        -Headers $headers `
        -Method Get `
        -TimeoutSec 15

    $cny = $response.balance_infos |
        Where-Object { $_.currency -eq "CNY" } |
        Select-Object -First 1
    $usd = $response.balance_infos |
        Where-Object { $_.currency -eq "USD" } |
        Select-Object -First 1

    if (-not $cny -and -not $usd) {
        throw "余额接口没有返回可显示的账户余额。"
    }

    return [PSCustomObject]@{
        Available     = [bool]$response.is_available
        CNY           = $cny
        USD           = $usd
        CheckedAt     = Get-Date
    }
}

function Format-Money($value, [string]$currency) {
    if ($null -eq $value) {
        return "--"
    }

    $number = 0.0
    if (-not [double]::TryParse([string]$value, [ref]$number)) {
        return [string]$value
    }

    if ($currency -eq "CNY") {
        return "¥{0:N2}" -f $number
    }

    return "{0:N2} USD" -f $number
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "DeepSeek 余额"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.Size = New-Object System.Drawing.Size(330, 190)
$form.MinimumSize = $form.Size
$form.MaximumSize = $form.Size
$form.BackColor = [System.Drawing.Color]::FromArgb(250, 251, 253)
$form.TopMost = $true
$form.ShowInTaskbar = $false

$workArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(
    ($workArea.Right - $form.Width - 20),
    ($workArea.Top + 20)
)

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(330, 42)
$header.BackColor = [System.Drawing.Color]::FromArgb(77, 107, 254)
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "DeepSeek 余额"
$title.ForeColor = [System.Drawing.Color]::White
$title.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    11,
    [System.Drawing.FontStyle]::Bold
)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(14, 10)
$header.Controls.Add($title)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "×"
$closeButton.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    12,
    [System.Drawing.FontStyle]::Regular
)
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(77, 107, 254)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Size = New-Object System.Drawing.Size(36, 32)
$closeButton.Location = New-Object System.Drawing.Point(290, 5)
$closeButton.Add_Click({ $form.Close() })
$header.Controls.Add($closeButton)

$dragPoint = New-Object System.Drawing.Point
$header.Add_MouseDown({
    param($sender, $eventArgs)
    $script:dragPoint = $eventArgs.Location
})
$header.Add_MouseMove({
    param($sender, $eventArgs)
    if ($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $form.Location = New-Object System.Drawing.Point(
            ($form.Location.X + $eventArgs.X - $script:dragPoint.X),
            ($form.Location.Y + $eventArgs.Y - $script:dragPoint.Y)
        )
    }
})

$balanceLabel = New-Object System.Windows.Forms.Label
$balanceLabel.Text = "读取中…"
$balanceLabel.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    24,
    [System.Drawing.FontStyle]::Bold
)
$balanceLabel.ForeColor = [System.Drawing.Color]::FromArgb(23, 32, 56)
$balanceLabel.AutoSize = $true
$balanceLabel.Location = New-Object System.Drawing.Point(14, 51)
$form.Controls.Add($balanceLabel)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = "正在连接 DeepSeek…"
$detailLabel.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    9,
    [System.Drawing.FontStyle]::Regular
)
$detailLabel.ForeColor = [System.Drawing.Color]::FromArgb(91, 101, 124)
$detailLabel.AutoSize = $false
$detailLabel.Size = New-Object System.Drawing.Size(300, 22)
$detailLabel.Location = New-Object System.Drawing.Point(16, 95)
$form.Controls.Add($detailLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "等待刷新"
$statusLabel.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    8,
    [System.Drawing.FontStyle]::Regular
)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(117, 126, 145)
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(16, 118)
$form.Controls.Add($statusLabel)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "刷新"
$refreshButton.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    9,
    [System.Drawing.FontStyle]::Regular
)
$refreshButton.Size = New-Object System.Drawing.Size(78, 30)
$refreshButton.Location = New-Object System.Drawing.Point(148, 148)
$refreshButton.BackColor = [System.Drawing.Color]::White
$refreshButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$refreshButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(210, 216, 229)
$form.Controls.Add($refreshButton)

$topUpButton = New-Object System.Windows.Forms.Button
$topUpButton.Text = "去充值"
$topUpButton.Font = New-Object System.Drawing.Font(
    "Microsoft YaHei UI",
    9,
    [System.Drawing.FontStyle]::Bold
)
$topUpButton.Size = New-Object System.Drawing.Size(86, 30)
$topUpButton.Location = New-Object System.Drawing.Point(232, 148)
$topUpButton.BackColor = [System.Drawing.Color]::FromArgb(77, 107, 254)
$topUpButton.ForeColor = [System.Drawing.Color]::White
$topUpButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$topUpButton.FlatAppearance.BorderSize = 0
$form.Controls.Add($topUpButton)

$topUpButton.Add_Click({
    Start-Process $topUpUrl
})

function Update-Balance {
    $refreshButton.Enabled = $false
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(117, 126, 145)
    $statusLabel.Text = "正在刷新…"

    try {
        $result = Get-DeepSeekBalance
        $display = if ($result.CNY) {
            $result.CNY
        } else {
            $result.USD
        }
        $currency = [string]$display.currency

        $balanceLabel.Text = Format-Money $display.total_balance $currency
        $detailLabel.Text = "赠金 {0}  ·  充值 {1}" -f `
            (Format-Money $display.granted_balance $currency),
            (Format-Money $display.topped_up_balance $currency)

        if ($result.Available) {
            $statusLabel.Text = "可用  ·  {0:HH:mm:ss} 自动刷新" -f $result.CheckedAt
        } else {
            $statusLabel.Text = "账户当前不可用  ·  {0:HH:mm:ss}" -f $result.CheckedAt
        }
    } catch {
        $balanceLabel.Text = "读取失败"
        $detailLabel.Text = $_.Exception.Message
        $statusLabel.Text = "稍后自动重试"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(190, 55, 65)
    } finally {
        $refreshButton.Enabled = $true
    }
}

$refreshButton.Add_Click({ Update-Balance })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = [Math]::Max(15, $RefreshSeconds) * 1000
$timer.Add_Tick({ Update-Balance })

$form.Add_Shown({
    Update-Balance
    $timer.Start()
})
$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
})

[System.Windows.Forms.Application]::Run($form)
