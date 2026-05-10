#!/bin/bash
# Triggers the parent_dag after a successful deploy.
# parent_dag orchestrates: pyspark_dag (Dataproc ingestion) → bigquery_dag (Medallion ETL)
set -euo pipefail

: "${COMPOSER_ENV:?ERROR: COMPOSER_ENV env var is not set}"
: "${COMPOSER_LOCATION:?ERROR: COMPOSER_LOCATION env var is not set}"

DAG_ID="parent_dag"
RUN_ID="cicd_run_$(date +%Y%m%d_%H%M%S)"

echo "============================================================"
echo " STEP 4/4 — Trigger Airflow DAG"
echo "============================================================"
echo "  Composer Env  : $COMPOSER_ENV"
echo "  Location      : $COMPOSER_LOCATION"
echo "  DAG ID        : $DAG_ID"
echo "  Run ID        : $RUN_ID"
echo ""

gcloud composer environments run "$COMPOSER_ENV" \
    --location "$COMPOSER_LOCATION" \
    dags trigger -- "$DAG_ID" --run-id "$RUN_ID"

echo ""
echo "DAG '$DAG_ID' triggered. Flow: parent_dag → pyspark_dag → bigquery_dag"
echo "Check Airflow UI for run status."
