import os
import pendulum
from airflow import DAG
from datetime import timedelta
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

# =========================
# CONFIG
# =========================
PROJECT_ID = "project-f1c63dcd-3c29-4fb0-95a"
LOCATION   = "asia-southeast1"

# In Composer: /home/airflow/gcs/data/BQ (GCS auto-mount)
# In CI/CD tests: set SQL_DIR env var to local sql/ folder
_SQL_BASE    = os.environ.get("SQL_DIR", "/home/airflow/gcs/data/BQ")
SQL_FILE_PATH_1 = f"{_SQL_BASE}/bronze.sql"
SQL_FILE_PATH_2 = f"{_SQL_BASE}/silver.sql"
SQL_FILE_PATH_3 = f"{_SQL_BASE}/gold.sql"

# Read SQL query from file
def read_sql_file(file_path: str) -> str:
    with open(file_path, "r", encoding="utf-8") as file:
        return file.read()

BRONZE_QUERY = read_sql_file(SQL_FILE_PATH_1)
SILVER_QUERY = read_sql_file(SQL_FILE_PATH_2)
GOLD_QUERY   = read_sql_file(SQL_FILE_PATH_3)

# Define default arguments
default_args = {
    "owner": "ThaoDTP",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "email": ["dthao161004@gmail.com"],
    "email_on_failure": False,
    "email_on_retry": False,
}

# =========================
# DAG
# =========================
with DAG(
    dag_id="bigquery_dag",
    start_date=pendulum.datetime(2024, 1, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    description="DAG to run the bigquery jobs",
    default_args=default_args,
    tags=["gcs", "bq", "etl/elt"],
) as dag:

    bronze_tables = BigQueryInsertJobOperator(
        task_id="bronze_tables",
        project_id=PROJECT_ID,
        location=LOCATION,
        configuration={
            "query": {
                "query": BRONZE_QUERY,
                "useLegacySql": False,
                "priority": "BATCH",
            }
        },
    )

    silver_tables = BigQueryInsertJobOperator(
        task_id="silver_tables",
        project_id=PROJECT_ID,
        location=LOCATION,
        configuration={
            "query": {
                "query": SILVER_QUERY,
                "useLegacySql": False,
                "priority": "BATCH",
            }
        },
    )

    gold_tables = BigQueryInsertJobOperator(
        task_id="gold_tables",
        project_id=PROJECT_ID,
        location=LOCATION,
        configuration={
            "query": {
                "query": GOLD_QUERY,
                "useLegacySql": False,
                "priority": "BATCH",
            }
        },
    )

# Task dependencies
bronze_tables >> silver_tables >> gold_tables
