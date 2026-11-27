param(
    [switch]$ForceConfig
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$PresetsDir = Join-Path $RepoRoot 'presets'

Write-Host "=== 1. Khoi phuc cau hinh Theme Mod ===" -ForegroundColor Cyan
$ThemeConfigSrc = Join-Path $PresetsDir 'personal_theme_config.json'
$ThemeConfigDst = Join-Path $RepoRoot 'theme_config.json'
if ((Test-Path $ThemeConfigSrc) -and ($ForceConfig -or -not (Test-Path $ThemeConfigDst))) {
    Copy-Item -Path $ThemeConfigSrc -Destination $ThemeConfigDst -Force
    Write-Host "Da chep theme_config.json"
} else {
    Write-Host "Giu nguyen theme_config.json hien co (dung -ForceConfig de ghi de)"
}

Write-Host "`n=== 2. Build va cai dat Antigravity Custom Theme Mod ===" -ForegroundColor Cyan
$CliExe = Join-Path $RepoRoot 'target\release\agy-theme.exe'
$DaemonExe = Join-Path $RepoRoot 'target\release\agy-theme-daemon.exe'
if (-not (Test-Path $CliExe) -or -not (Test-Path $DaemonExe)) {
    Push-Location $RepoRoot
    try {
        cargo build --release
        if ($LASTEXITCODE -ne 0) { throw "cargo build --release that bai" }
    } finally {
        Pop-Location
    }
}
& $CliExe --root $RepoRoot build
if ($LASTEXITCODE -ne 0) { throw "agy-theme build that bai" }
& $CliExe --root $RepoRoot install
if ($LASTEXITCODE -ne 0) { throw "agy-theme install that bai" }

Write-Host "`n=== 3. Cai dat Usage Monitor (ban Viet hoa + composer-top) ===" -ForegroundColor Cyan
$PluginsDir = Join-Path $env:USERPROFILE '.gemini\config\plugins'
$UsageMonitorDir = Join-Path $PluginsDir 'usage-monitor'
New-Item -ItemType Directory -Path $PluginsDir -Force | Out-Null

if (Test-Path (Join-Path $UsageMonitorDir '.git')) {
    Write-Host "Dang cap nhat usage-monitor..."
    git -C $UsageMonitorDir fetch origin
    git -C $UsageMonitorDir checkout custom/personal
    git -C $UsageMonitorDir pull --ff-only
} else {
    if (Test-Path $UsageMonitorDir) {
        Remove-Item -Path $UsageMonitorDir -Recurse -Force
    }
    git clone --filter=blob:none -b custom/personal https://github.com/TakaLuong-design/antigravity-usage-monitor.git $UsageMonitorDir
}

Write-Host "`n=== 4. Khoi phuc cau hinh Usage Monitor ===" -ForegroundColor Cyan
$UsageDataDir = Join-Path $env:USERPROFILE '.gemini\antigravity\sidecar_data\usage-monitor\panel\data'
$UsageConfigSrc = Join-Path $PresetsDir 'personal_usage_settings.json'
$UsageConfigDst = Join-Path $UsageDataDir 'settings.json'
New-Item -ItemType Directory -Path $UsageDataDir -Force | Out-Null
if ((Test-Path $UsageConfigSrc) -and ($ForceConfig -or -not (Test-Path $UsageConfigDst))) {
    Copy-Item -Path $UsageConfigSrc -Destination $UsageConfigDst -Force
    Write-Host "Da chep settings.json cho Usage Monitor"
} else {
    Write-Host "Giu nguyen settings.json hien co (dung -ForceConfig de ghi de)"
}

Write-Host "`n=== HOAN TAT ===" -ForegroundColor Green
Write-Host "1. Thoat hoan toan Antigravity (khay he thong -> Quit) va mo lai tu shortcut."
Write-Host "2. Vao Customizations -> Installed -> bat plugin 'usage-monitor'."
