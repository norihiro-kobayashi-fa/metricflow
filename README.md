# MetricFlow 評価環境

dbt MetricFlow の評価・学習用 Docker Compose 環境です。

## 技術スタック

| コンポーネント | バージョン | 役割 |
|---|---|---|
| PostgreSQL | 16 | データウェアハウス |
| dbt-core | 1.11.x | データ変換・セマンティックレイヤー |
| dbt-postgres | 1.10.x | PostgreSQL アダプター |
| dbt-metricflow | 0.12.x | メトリクス定義・クエリエンジン |
| pgAdmin 4 | latest | DB 可視化 UI |

## ディレクトリ構造

```
metricflow/
├── docker-compose.yml
├── docker/
│   ├── Dockerfile.dbt          # dbt + MetricFlow イメージ
│   ├── postgres-init/          # PostgreSQL 初期化 SQL
│   └── pgadmin-servers.json    # pgAdmin 自動接続設定
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   ├── seeds/                  # サンプルデータ (Jaffle Shop 風)
│   │   ├── raw_customers.csv
│   │   ├── raw_orders.csv
│   │   └── raw_payments.csv
│   └── models/
│       ├── staging/            # ステージングモデル (view)
│       ├── marts/              # マートモデル (table)
│       └── metrics/            # MetricFlow セマンティックモデル・メトリクス定義
│           ├── semantic_models.yml
│           └── metrics.yml
└── scripts/
    ├── setup.sh                # ワンコマンドセットアップ
    └── run_queries.sh          # MetricFlow クエリ評価
```

## クイックスタート

### 1. セットアップ (初回のみ)

```bash
# Windows の場合は Git Bash / WSL で実行
bash scripts/setup.sh
```

または手動で:

```bash
# サービス起動
docker compose up -d --build

# dbt パッケージインストール
docker compose exec dbt dbt deps

# データ投入 → モデル実行 → テスト
docker compose exec dbt dbt seed
docker compose exec dbt dbt run
docker compose exec dbt dbt test
```

### 2. MetricFlow 操作

```bash
# 設定の検証
docker compose exec dbt mf validate-configs
# ※ WARNINGS: 2 が表示されるが既知の問題で動作に影響なし（後述）

# メトリクス一覧
docker compose exec dbt mf list metrics

# ディメンション一覧
docker compose exec dbt mf list dimensions --metrics revenue

# クエリ実行
docker compose exec dbt mf query --metrics revenue --group-by metric_time__month
```

### 3. 評価クエリを一括実行

```bash
bash scripts/run_queries.sh
```

## 定義済みメトリクス

| メトリクス名 | 種別 | 説明 |
|---|---|---|
| `revenue` | simple | 売上合計 |
| `order_count` | simple | 注文件数 |
| `average_order_value` | simple | 平均注文金額 |
| `completed_orders` | simple | 完了注文件数 |
| `completion_rate` | ratio | 注文完了率 |
| `total_customers` | simple | 顧客総数 |
| `active_customers` | simple | アクティブ顧客数 |
| `customer_activation_rate` | ratio | 顧客活性化率 |
| `average_customer_ltv` | simple | 平均顧客生涯価値 |
| `cumulative_revenue` | cumulative | 累積売上 |
| `cumulative_customers` | cumulative | 累積顧客数 |
| `revenue_per_customer` | derived | 顧客1人あたり売上 |

## アクセス先

| サービス | URL | 認証情報 |
|---|---|---|
| pgAdmin | http://localhost:5050 | admin@example.com / admin |
| PostgreSQL | localhost:5432 | dbt / dbt_password |

## 既知の問題

### mf validate-configs で WARNINGS: 2 が表示される

`cumulative_revenue` と `cumulative_customers` に対して以下の警告が出る：

```
WARNING: Cumulative metric '...' should not have both a measure and a metric as inputs.
```

**原因:** dbt-metricflow 0.12.x の内部変換ルールが `measure:` 指定から自動的に `metric` 参照を生成するため、バリデーター上で両方がセットされた状態になる。新形式（`cumulative_type_params.metric:`）は dbt-core 1.11.x の JSON スキーマで未対応のため、YAML では記述できない。

**影響:** なし。`ERRORS: 0, FUTURE_ERRORS: 0` であり、クエリは正常に実行される。

## サービス停止・削除

```bash
# 停止
docker compose down

# データも含めて完全削除
docker compose down -v
```
