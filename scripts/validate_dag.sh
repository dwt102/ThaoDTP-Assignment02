#!/bin/bash
# Validates Python syntax for all DAG files. Exits non-zero on any error
# so Cloud Build aborts before deploying a broken DAG.
set -euo pipefail

echo "============================================================"
echo " STEP 1/4 — DAG Syntax Validation"
echo "============================================================"

PASS=0
FAIL=0

for dag_file in dags/*.py; do
    if python3 -m py_compile "$dag_file" 2>&1; then
        echo "  [PASS] $dag_file"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $dag_file"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "Result: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    echo "Validation FAILED — aborting deploy."
    exit 1
fi

echo "All DAGs passed syntax validation."
