from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    "owner": "data-platform",
    "depends_on_past": False,
    "email_on_failure": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(minutes=30),
}


def notify_failure(context):
    """
    Notificación ante fallos.

    En una implementación real, aquí se enviaría una alerta a Slack,
    Teams, correo electrónico o un sistema de observabilidad.
    """
    task_instance = context.get("task_instance")
    print(
        f"ALERT: task '{task_instance.task_id}' in DAG "
        f"'{task_instance.dag_id}' failed."
    )


def run_airbyte_sync_stub(**context):
    """
    Representa la sincronización de Airbyte definida en Fase 1.

    En una implementación real, esta función llamaría a la API de Airbyte
    para lanzar las conexiones definidas en ingestion/airbyte.yaml y
    esperaría a que finalicen correctamente.
    """
    sources = [
        "raw_workers",
        "raw_visits",
        "raw_routes",
        "raw_projects",
        "raw_campaigns",
        "pos_omni",
        "pos_gi",
    ]

    print("Starting Airbyte ingestion stub.")
    print(f"Sources to synchronise: {', '.join(sources)}")
    print(
        "Destination: primer_impacto_postgres / database=primer_impacto / "
        "schema=raw"
    )
    print("Sync mode: full_refresh | Destination sync mode: overwrite")
    print("Airbyte ingestion stub completed successfully.")


with DAG(
    dag_id="primer_impacto_elt_pipeline",
    description=(
        "Runs the Airbyte ingestion stub and then builds and tests the dbt project."
    ),
    start_date=datetime(2026, 1, 1),
    schedule="0 6 * * *",
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    on_failure_callback=notify_failure,
    tags=["elt", "airbyte", "dbt", "primer_impacto"],
) as dag:

    airbyte_sync = PythonOperator(
        task_id="airbyte_sync",
        python_callable=run_airbyte_sync_stub,
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=(
            "cd /opt/dbt && dbt build --profiles-dir /opt/dbt"
        ),
        on_failure_callback=notify_failure,
    )

    airbyte_sync >> dbt_build