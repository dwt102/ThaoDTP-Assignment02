import airflow.providers.google.cloud.operators.dataproc as _mod
from airflow.models.baseoperator import BaseOperator


class _ClusterLifecycleStub(BaseOperator):
    template_fields: list = []

    def __init__(self, *args, task_id: str, trigger_rule: str = "all_success", **kwargs):
        super().__init__(task_id=task_id, trigger_rule=trigger_rule)

    def execute(self, context):
        pass


for _name in ("DataprocStartClusterOperator", "DataprocStopClusterOperator"):
    if not hasattr(_mod, _name):
        setattr(_mod, _name, type(_name, (_ClusterLifecycleStub,), {}))
