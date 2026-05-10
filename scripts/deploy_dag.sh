#!/bin/bash
# Deploys all artefacts to Cloud Composer and GCS:
#   1. DAG files      → Composer DAGs bucket
#   2. SQL files      → Composer data/BQ/ (bq_dag.py reads from here)
#   3. Ingestion scripts → Composer data/Ingestion/ (pyspark_dag.py reads from here)
set -euo pipefail

: "${COMPOSER_BUCKET:?ERROR: COMPOSER_BUCKET env var is not set}"

echo "============================================================"
echo " STEP 3/4 — Deploy to Cloud Composer"
echo " Bucket: $COMPOSER_BUCKET"
echo "============================================================"

# 1. Deploy DAGs
echo ""
echo "--- Deploying DAGs ---"
gsutil -m cp dags/*.py "gs://${COMPOSER_BUCKET}/dags/"
echo "  [OK] DAGs deployed"

# 2. Deploy SQL files (bronze.sql, silver.sql, gold.sql)
echo ""
echo "--- Deploying SQL files ---"
gsutil -m cp sql/*.sql "gs://${COMPOSER_BUCKET}/data/BQ/"
echo "  [OK] SQL files deployed"

# 3. Deploy PySpark ingestion scripts
echo ""
echo "--- Deploying Ingestion scripts ---"
gsutil -m cp ingestion/*.py "gs://${COMPOSER_BUCKET}/data/Ingestion/"
echo "  [OK] Ingestion scripts deployed"

echo ""
echo "All artefacts deployed successfully."
