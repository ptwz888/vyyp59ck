# push-lines.ps1 — 把最新 lines.json 发布到 GitHub（App 的「上游通道」从这里自动拉取）
#
# 已经配好（账号 ptwz888 / 仓库 vyyp59ck / 凭据在 Windows 凭据管理器），改完线路直接跑：
#   powershell -ExecutionPolicy Bypass -File lines-dist\push-lines.ps1
# → 推送后 12 小时内（TTL），所有装着的 App 启动时自动拉到新线路，无需重装 APK。
# 如果换号/换仓库：-User 新用户名 -Repo 新仓库名（凭据管理器里也更新 github.com 的凭据）。
param(
    [string]$User = "ptwz888",
    [string]$Repo = "vyyp59ck"
)
# git 的 stderr（进度/告警）在 PS5.1 + Stop 下会误报为错误：改用 Continue，靠 $LASTEXITCODE 判断。
$ErrorActionPreference = "Continue"
$dist = $PSScriptRoot
$root = Split-Path -Parent $dist

# 1. 同步母版：仓库根 lines.json 覆盖到发布目录
Copy-Item (Join-Path $root "lines.json") (Join-Path $dist "lines.json") -Force

# 2. 初始化 git 仓库（仅首次）
if (-not (Test-Path (Join-Path $dist ".git"))) {
    git -C $dist init -b main | Out-Null
    git -C $dist config user.name $User
    git -C $dist config user.email "117571590@qq.com"
    git -C $dist remote add origin "https://github.com/$User/$Repo.git"
    Set-Content (Join-Path $dist "README.md") "config distribution"
}

# 3. 提交并推送（远端如有新提交先变基，避免未来冲突）
git -C $dist add lines.json README.md
git -C $dist commit -m "lines update $(Get-Date -Format 'yyyy-MM-dd HH:mm')" --allow-empty
git -C $dist fetch origin main 2>$null
if ($LASTEXITCODE -eq 0) { git -C $dist rebase origin/main 2>$null }
git -C $dist push -u origin main
if ($LASTEXITCODE -ne 0) { throw "push 失败：检查网络（github.com 时好时坏，重跑一次）或凭据管理器中的 github.com 凭据" }

Write-Host ""
Write-Host "✔ 已发布。App 端生效地址："
Write-Host "  https://raw.githubusercontent.com/$User/$Repo/main/lines.json"
Write-Host "  https://ghfast.top/https://raw.githubusercontent.com/$User/$Repo/main/lines.json （国内直连）"
Write-Host "下次 App 启动（或 TTL 过期后）自动拉取，无需重装 APK。"
