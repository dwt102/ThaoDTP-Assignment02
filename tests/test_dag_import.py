"""
Unit tests for all three Airflow DAG files.
Runs inside Cloud Build (Step 2) before any deployment.
A failed test aborts the pipeline — no broken DAG reaches Composer.
"""

import importlib
import os
import sys
import unittest

DAG_DIR = os.path.join(os.path.dirname(__file__), "..", "dags")
sys.path.insert(0, DAG_DIR)


def _dag_modules():
    return [
        f[:-3]
        for f in os.listdir(DAG_DIR)
        if f.endswith(".py") and not f.startswith("_")
    ]


# ── Parametrized: every DAG file must import cleanly ──────────────────────────

class TestDagImports(unittest.TestCase):
    def test_parent_dag_imports(self):
        try:
            importlib.import_module("parent_dag")
        except Exception as exc:
            self.fail(f"parent_dag.py failed to import: {exc}")

    def test_pyspark_dag_imports(self):
        try:
            importlib.import_module("pyspark_dag")
        except Exception as exc:
            self.fail(f"pyspark_dag.py failed to import: {exc}")

    def test_bq_dag_imports(self):
        try:
            importlib.import_module("bq_dag")
        except Exception as exc:
            self.fail(f"bq_dag.py failed to import: {exc}")


# ── parent_dag assertions ──────────────────────────────────────────────────────

class TestParentDag(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = importlib.import_module("parent_dag")

    def test_dag_id(self):
        self.assertEqual(self.mod.dag.dag_id, "parent_dag")

    def test_schedule(self):
        self.assertEqual(self.mod.dag.schedule_interval, "0 5 * * *")

    def test_no_catchup(self):
        self.assertFalse(self.mod.dag.catchup)

    def test_task_ids(self):
        task_ids = {t.task_id for t in self.mod.dag.tasks}
        self.assertIn("trigger_pyspark_dag", task_ids)
        self.assertIn("trigger_bigquery_dag", task_ids)

    def test_dependency_order(self):
        tasks = {t.task_id: t for t in self.mod.dag.tasks}
        downstream = {t.task_id for t in tasks["trigger_pyspark_dag"].downstream_list}
        self.assertIn("trigger_bigquery_dag", downstream)


# ── pyspark_dag assertions ─────────────────────────────────────────────────────

class TestPysparkDag(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = importlib.import_module("pyspark_dag")

    def test_dag_id(self):
        self.assertEqual(self.mod.dag.dag_id, "pyspark_dag")

    def test_no_catchup(self):
        self.assertFalse(self.mod.dag.catchup)

    def test_required_tasks(self):
        task_ids = {t.task_id for t in self.mod.dag.tasks}
        required = {"start_cluster", "pyspark_task_1", "pyspark_task_2",
                    "pyspark_task_3", "pyspark_task_4", "stop_cluster"}
        self.assertTrue(required.issubset(task_ids))

    def test_stop_cluster_is_last(self):
        tasks = {t.task_id: t for t in self.mod.dag.tasks}
        upstream = {t.task_id for t in tasks["stop_cluster"].upstream_list}
        self.assertIn("pyspark_task_4", upstream)


# ── bq_dag assertions ──────────────────────────────────────────────────────────

class TestBqDag(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = importlib.import_module("bq_dag")

    def test_dag_id(self):
        self.assertEqual(self.mod.dag.dag_id, "bigquery_dag")

    def test_no_catchup(self):
        self.assertFalse(self.mod.dag.catchup)

    def test_required_tasks(self):
        task_ids = {t.task_id for t in self.mod.dag.tasks}
        self.assertIn("bronze_tables", task_ids)
        self.assertIn("silver_tables", task_ids)
        self.assertIn("gold_tables", task_ids)

    def test_medallion_order(self):
        tasks = {t.task_id: t for t in self.mod.dag.tasks}
        # bronze → silver
        self.assertIn("silver_tables",
                      {t.task_id for t in tasks["bronze_tables"].downstream_list})
        # silver → gold
        self.assertIn("gold_tables",
                      {t.task_id for t in tasks["silver_tables"].downstream_list})


if __name__ == "__main__":
    unittest.main()
