#Requires -Version 5.1
<#
.SYNOPSIS
    MetricFlow 評価環境セットアップスクリプト (Windows PowerShell / pwsh)
.EXAMPLE
    .\scripts\setup.ps1
    .\scripts\setup.ps1 -SkipBuild   # イメージ再ビルドをスキップ
#>
param(
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── ヘルパー関数 ──────────────────────────────────────────
function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host ""
    Write-Host "[$Step] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Assert-Command {
    param([string]$Name, [string]$InstallHint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Fail "'$Name' が見つかりません。$InstallHint"
        exit 1
    }
}

# ── 前提コマンド確認 ──────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host " MetricFlow 評価環境セットアップ" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

Assert-Command 'docker'         'Docker Desktop をインストールしてください: https://www.docker.com/products/docker-desktop'
Assert-Command 'docker-compose' 'Docker Desktop に含まれています。Docker Desktop を起動してください。'

# Docker デーモンが起動しているか確認
try {
    docker info *>$null
}
catch {
    Write-Fail 'Docker デーモンが起動していません。Docker Desktop を起動してください。'
    exit 1
}

# ── プロジェクトルートへ移動 ──────────────────────────────
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot
Write-Host "作業ディレクトリ: $ProjectRoot" -ForegroundColor DarkGray

# ── Step 1: Docker Compose 起動 ───────────────────────────
Write-Step '1/4' 'Docker Compose でサービスを起動中...'

$buildFlag = if ($SkipBuild) { @() } else { @('--build') }
docker compose up -d @buildFlag

if ($LASTEXITCODE -ne 0) {
    Write-Fail 'docker compose up に失敗しました。'
    exit 1
}

# ── Step 2: PostgreSQL ヘルスチェック待機 ─────────────────
Write-Step '2/4' 'PostgreSQL の起動を待機中...'

$maxRetry = 30
$retryCount = 0
$ready = $false

while ($retryCount -lt $maxRetry) {
    $result = docker compose exec postgres pg_isready -U dbt -d dbt_db 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        break
    }
    $retryCount++
    Write-Host "  待機中... ($retryCount/$maxRetry)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
}

if (-not $ready) {
    Write-Fail "PostgreSQL が $maxRetry 回のリトライ後も起動しませんでした。"
    Write-Host 'ログを確認: docker compose logs postgres' -ForegroundColor Yellow
    exit 1
}

Write-Success '  PostgreSQL 起動確認 OK'

# ── Step 3: dbt パッケージインストール ───────────────────
Write-Step '3/4' 'dbt パッケージをインストール中...'

docker compose exec dbt dbt deps
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'dbt deps に失敗しました。'
    exit 1
}

# ── Step 4: dbt パイプライン実行 ─────────────────────────
Write-Step '4/4' 'dbt パイプラインを実行中 (seed → run → test)...'

$commands = @(
    'dbt seed --select raw_customers raw_orders raw_payments',
    'dbt run',
    'dbt test'
)

foreach ($cmd in $commands) {
    Write-Host "  実行: $cmd" -ForegroundColor DarkGray
    docker compose exec dbt bash -c $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "'$cmd' が失敗しました。"
        Write-Host 'ログを確認: docker compose logs dbt' -ForegroundColor Yellow
        exit 1
    }
}

# ── 完了メッセージ ────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host " セットアップ完了!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "利用可能なサービス:" -ForegroundColor White
Write-Host "  - pgAdmin : http://localhost:5050"
Write-Host "              (email: admin@example.com / password: admin)"
Write-Host ""
Write-Host "MetricFlow コマンド例:" -ForegroundColor White
Write-Host "  docker compose exec dbt mf validate-configs"
Write-Host "  docker compose exec dbt mf list metrics"
Write-Host "  docker compose exec dbt mf list dimensions --metrics revenue"
Write-Host "  docker compose exec dbt mf query --metrics revenue --group-by metric_time__month"
Write-Host ""
Write-Host "クエリ評価を一括実行するには:" -ForegroundColor White
Write-Host "  .\scripts\run_queries.ps1"
Write-Host ""
