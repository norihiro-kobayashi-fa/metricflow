#!/bin/bash
set -e

echo "================================================"
echo " MetricFlow 評価環境セットアップ"
echo "================================================"

echo ""
echo "[1/4] Docker Compose でサービスを起動中..."
docker compose up -d --build

echo ""
echo "[2/4] PostgreSQL の起動を待機中..."
docker compose exec postgres pg_isready -U dbt -d dbt_db
sleep 3

echo ""
echo "[3/4] dbt パッケージをインストール中..."
docker compose exec dbt dbt deps

echo ""
echo "[4/4] dbt パイプラインを実行中..."
docker compose exec dbt bash -c "
  dbt seed --select raw_customers raw_orders raw_payments &&
  dbt run &&
  dbt test
"

echo ""
echo "================================================"
echo " セットアップ完了!"
echo "================================================"
echo ""
echo "利用可能なサービス:"
echo "  - pgAdmin:  http://localhost:5050"
echo "              (email: admin@example.com / password: admin)"
echo ""
echo "MetricFlow コマンド例:"
echo "  docker compose exec dbt mf validate-configs"
echo "  docker compose exec dbt mf list metrics"
echo "  docker compose exec dbt mf list dimensions --metrics revenue"
echo "  docker compose exec dbt mf query --metrics revenue --group-by metric_time"
echo ""
