# Healthcare ETL Pipeline — CI/CD Assignment
**Student:** Đặng Thị Phương Thảo  
**Course:** Google Cloud Data Engineering  
**Architecture:** V2 Batch (Dataproc + BigQuery Medallion) with CI/CD via Cloud Build

---

## 2. GitHub Repository

### Repository Structure
```
ThaoDTP_Assignment02/
├── dags/
│   ├── parent_dag.py               # Orchestrator: triggers pyspark_dag → bigquery_dag (daily 5AM)
│   ├── pyspark_dag.py              # Dataproc: PostgreSQL → GCS Landing (4 PySpark jobs)
│   └── bq_dag.py                   # Medallion: Bronze → Silver → Gold (BigQuery)
├── ingestion/
│   ├── hospitalA_postgresToLanding.py   # PySpark: Hospital A PostgreSQL → GCS
│   └── hospitalB_postgresToLanding.py   # PySpark: Hospital B PostgreSQL → GCS
├── sql/
│   ├── bronze.sql                  # External Tables on GCS (Hospital A, B, Claims, CPT)
│   ├── silver.sql                  # CDM dimension/fact tables + SCD Type 2
│   └── gold.sql                    # 6 Analytical aggregation tables
├── scripts/
│   ├── validate_dag.sh             # CI Step 2: py_compile all DAG files
│   ├── deploy_dag.sh               # CI Step 4: deploy DAGs + SQL + Ingestion → GCS
│   └── trigger_dag.sh              # CI Step 5: trigger parent_dag in Composer
├── tests/
│   └── test_dag_import.py          # CI Step 3: pytest unit tests for all 3 DAGs
├── cloudbuild.yaml                 # CI/CD pipeline definition (5 steps)
├── requirements.txt
└── README.md
```

---

## 3. Cloud Build CI/CD Pipeline

### CI/CD Flow (triggered on push to `main`)
```
Push to GitHub main
        │
        ▼
Cloud Build Trigger
        │
        ├─ Step 1: install-deps     pip install -r requirements.txt
        ├─ Step 2: validate-dags    py_compile parent_dag, pyspark_dag, bq_dag
        ├─ Step 3: run-tests        pytest tests/test_dag_import.py -v
        ├─ Step 4: deploy-all       gsutil cp DAGs + SQL + Ingestion scripts → GCS
        └─ Step 5: trigger-dag      gcloud composer ... dags trigger parent_dag
```

### Artefacts deployed in Step 4
| Artefact | Source | GCS Destination |
|---|---|---|
| DAG files | `dags/*.py` | `gs://<COMPOSER_BUCKET>/dags/` |
| SQL files | `sql/*.sql` | `gs://<COMPOSER_BUCKET>/data/BQ/` |
| Ingestion scripts | `ingestion/*.py` | `gs://<COMPOSER_BUCKET>/data/Ingestion/` |

### Required GCP permissions for Cloud Build Service Account
```
roles/composer.worker
roles/bigquery.dataEditor
roles/storage.objectAdmin
roles/dataproc.editor
```

### Environment variables (cloudbuild.yaml substitutions)
| Variable | Value |
|---|---|
| `_COMPOSER_BUCKET` | `gs://asia-southeast1-healthcare--5e26beaf-bucket` |
| `_COMPOSER_ENV` | `healthcare-composer` |
| `_COMPOSER_LOCATION` | `asia-southeast1` |

---

## 4. Airflow DAGs

### DAG Architecture
```
parent_dag  (schedule: 0 5 * * *  — daily 5AM UTC)
│
├─► pyspark_dag  (schedule: None — triggered by parent)
│       start_cluster
│       → pyspark_task_1  (hospitalA_postgresToLanding.py)
│       → pyspark_task_2  (hospitalB_postgresToLanding.py)
│       → pyspark_task_3  (claims.py)
│       → pyspark_task_4  (cpt_codes.py)
│       → stop_cluster    (TriggerRule.ALL_DONE — runs even if jobs fail)
│
└─► bigquery_dag  (schedule: None — triggered after pyspark_dag completes)
        bronze_tables   (External Tables via bronze.sql)
        → silver_tables (CDM + SCD2 via silver.sql)
        → gold_tables   (6 Analytical tables via gold.sql)
```

### parent_dag
| Property | Value |
|---|---|
| `dag_id` | `parent_dag` |
| `schedule` | `0 5 * * *` (daily 5AM UTC) |
| `catchup` | `False` |
| Operator | `TriggerDagRunOperator` with `wait_for_completion=True` |

### pyspark_dag
| Property | Value |
|---|---|
| `dag_id` | `pyspark_dag` |
| `schedule` | `None` (triggered by parent) |
| `catchup` | `False` |
| Cluster | `healthcare-cluster` (asia-southeast1) |
| `stop_cluster` trigger rule | `TriggerRule.ALL_DONE` |

### bq_dag (bigquery_dag)
| Property | Value |
|---|---|
| `dag_id` | `bigquery_dag` |
| `schedule` | `None` (triggered by parent) |
| `catchup` | `False` |
| Operator | `BigQueryInsertJobOperator` (BATCH priority) |
| SQL path | `/home/airflow/gcs/data/BQ/` (auto-mounted from Composer bucket) |

---

## 5. BigQuery Medallion Architecture

### Bronze Layer (`bronze.sql`)
- Creates BigQuery External Tables pointing to GCS CSV files
- Sources: Hospital A patients, Hospital B patients, Claims, CPT Codes
- No transformation — raw data preserved

### Silver Layer (`silver.sql`)
- CDM (Common Data Model) — unified schema across Hospital A + B
- Composite key: `CONCAT(id, '-', datasource)` to avoid ID collision between hospitals
- **SCD Type 2** on `dim_patients`: tracks history with `is_current`, `inserted_date`, `modified_date`
- `is_quarantined` flag: marks bad records without deleting them
- Dimension tables: `dim_patients`, `dim_departments`, `dim_providers`
- Fact tables: `fact_encounters`, `fact_transactions`, `fact_claims`

### Gold Layer (`gold.sql`)
6 analytical aggregation tables built on top of Silver:
1. `total_charge_per_provider_dept`
2. `financial_metrics`
3. `patient_encounter_summary`
4. `claim_approval_rate`
5. `department_workload`
6. `monthly_revenue_trend`

---

## 6. Architecture: V2 Batch

### V2 Batch Pipeline
```
Hospital A PostgreSQL ─┐
Hospital B PostgreSQL ─┤─► Dataproc (PySpark) ─► GCS Landing
Claims CSV ────────────┤
CPT Codes CSV ─────────┘
                                │
                                ▼
                    BigQuery (Medallion)
                    Bronze (External Tables on GCS)
                        → Silver (CDM + SCD2)
                            → Gold (Analytics)
```

### V3 Extension (Streaming Layer)
| Component | Role |
|---|---|
| **Producers** | Real-time event sources |
| **Pub/Sub Topic** | Message queue for streaming events |
| **Dataflow** | Apache Beam job: validate + dedup + late data handling |
| **DLQ** | Dead Letter Queue for failed/malformed messages |
| **Apache Beam** | Replay DLQ messages after fixing schema errors |

The V2 batch pipeline remains unchanged — V3 adds a parallel streaming path feeding into the same Bronze/Silver/Gold BigQuery layers.
