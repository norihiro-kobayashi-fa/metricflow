#Requires -Version 5.1
<#
.SYNOPSIS
    MetricFlow 評価用クエリ集 (Windows PowerShell / pwsh)
.EXAMPLE
    .\scripts\run_queries.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Dbt = 'docker compose exec dbt'

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " MetricFlow クエリ評価" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

function Invoke-Dbt {
    param([string[]]$CmdArgs)
    $cmd = "docker compose exec dbt " + ($CmdArgs -join ' ')
    Write-Host "  $cmd" -ForegroundColor DarkGray
    docker compose exec dbt @CmdArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] コマンドが失敗しました (exit $LASTEXITCODE)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "--- 設定の検証 ---" -ForegroundColor White
Invoke-Dbt 'mf', 'validate-configs'

Write-Host ""
Write-Host "--- 定義済みメトリクス一覧 ---" -ForegroundColor White
Invoke-Dbt 'mf', 'list', 'metrics'

Write-Host ""
Write-Host "--- revenue メトリクスのディメンション一覧 ---" -ForegroundColor White
Invoke-Dbt 'mf', 'list', 'dimensions', '--metrics', 'revenue'

Write-Host ""
Write-Host "--- 月次売上 (time_grain: month) ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', '--metrics', 'revenue', '--group-by', 'metric_time__month'

Write-Host ""
Write-Host "--- 国別・月次売上 ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', `
    '--metrics', 'revenue,order_count', `
    '--group-by', 'metric_time__month,order__country', `
    '--order', 'metric_time__month,order__country'

Write-Host ""
Write-Host "--- 支払い方法別 売上・注文件数 ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', `
    '--metrics', 'revenue,order_count,average_order_value', `
    '--group-by', 'order__payment_method'

Write-Host ""
Write-Host "--- 注文完了率 (completion_rate) ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', `
    '--metrics', 'completion_rate,completed_orders,order_count', `
    '--group-by', 'metric_time__month'

Write-Host ""
Write-Host "--- 顧客メトリクス ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', `
    '--metrics', 'total_customers,active_customers,customer_activation_rate', `
    '--group-by', 'metric_time__month'

Write-Host ""
Write-Host "--- 累積売上 ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', '--metrics', 'cumulative_revenue', '--group-by', 'metric_time__month'

Write-Host ""
Write-Host "--- 顧客1人あたり売上 (derived metric) ---" -ForegroundColor White
Invoke-Dbt 'mf', 'query', '--metrics', 'revenue_per_customer', '--group-by', 'metric_time__month'

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " クエリ評価完了" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
