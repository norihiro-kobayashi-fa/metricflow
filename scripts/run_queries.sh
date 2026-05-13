#!/bin/bash
# MetricFlow 評価用クエリ集

DBT="docker compose exec dbt"

echo "================================================"
echo " MetricFlow クエリ評価"
echo "================================================"

echo ""
echo "--- 設定の検証 ---"
$DBT mf validate-configs

echo ""
echo "--- 定義済みメトリクス一覧 ---"
$DBT mf list metrics

echo ""
echo "--- revenue メトリクスのディメンション一覧 ---"
$DBT mf list dimensions --metrics revenue

echo ""
echo "--- 月次売上 (time_grain: month) ---"
$DBT mf query \
  --metrics revenue \
  --group-by metric_time__month

echo ""
echo "--- 国別・月次売上 ---"
$DBT mf query \
  --metrics revenue,order_count \
  --group-by metric_time__month,order__country \
  --order metric_time__month,order__country

echo ""
echo "--- 支払い方法別 売上・注文件数 ---"
$DBT mf query \
  --metrics revenue,order_count,average_order_value \
  --group-by order__payment_method

echo ""
echo "--- 注文完了率 (completion_rate) ---"
$DBT mf query \
  --metrics completion_rate,completed_orders,order_count \
  --group-by metric_time__month

echo ""
echo "--- 顧客メトリクス ---"
$DBT mf query \
  --metrics total_customers,active_customers,customer_activation_rate \
  --group-by metric_time__month

echo ""
echo "--- 累積売上 ---"
$DBT mf query \
  --metrics cumulative_revenue \
  --group-by metric_time__month

echo ""
echo "--- 顧客1人あたり売上 (derived metric) ---"
$DBT mf query \
  --metrics revenue_per_customer \
  --group-by metric_time__month

echo ""
echo "================================================"
echo " クエリ評価完了"
echo "================================================"
