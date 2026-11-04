# Phase 3 — Orchestration with Airflow notes

## Enfoque actual

La implementación actual utiliza un único DAG de Apache Airflow (primer_impacto_elt_pipeline) para orquestar todo el flujo de trabajo ELT.

El pipeline consta de dos tareas secuenciales:

1. *Ingesta con Airbyte (`airbyte_sync`):* actualmente se utiliza una tarea simulada (stub), ya que en la Fase 1 se definió la configuración de ingesta, pero no se llegó a implementar el cliente de la API de Airbyte. Esta tarea representa la sincronización de los siete conjuntos de datos de origen (archivos CSV) hacia el esquema raw de PostgreSQL.
2. *Transformación con dbt (`dbt_build`):* una vez finalizada correctamente la ingesta, se ejecuta dbt build, que se encarga de transformar los datos y comprobar su calidad. Este proceso incluye los modelos de staging, los modelos de marts (entre ellos dim_pos_unified y fct_visits) y los tests de dbt.

La dependencia entre ambas tareas garantiza que las transformaciones solo se ejecuten cuando la ingesta haya terminado correctamente.


## Posibles mejoras futuras

### Evolución hacia un Airbyte real

La tare `airbyte_sync` debería sustituirse por una integración real que:

- Lea el archivo `ingestion/airbyte.yaml`.
- Cree o actualice las fuentes de Airbyte, el destino y las conexiones.
- Lance la sincronización de cada conexión.
- Consulte periódicamente el estado de los trabajos hasta que finalicen.
- Marque la tarea de Airflow como fallida si alguna sincronización falla.

### Control de acceso

En un entorno de producción con varios usuarios y equipos, introduciría un sistema de control de acceso más granular.

Los posibles roles serían:
- *Administrador:* acceso completo a la configuración de Airflow y la infraestructura.
- *Ingeniero de datos:* permisos para gestionar los DAGs y monitorizar las ejecuciones de los pipelines.
- *Analista de datos:* acceso de solo lectura a la monitorización de los pipelines y a los resultados de las ejecuciones.

También consideraría separar los permisos de acceso a la base de datos entre los procesos de ingesta y transformación, siguiendo el principio de mínimo privilegio. Esto mejoraría la seguridad, la trazabilidad y el gobierno de los datos.


### Evolución hacia una orquestación a gran escala

Si en el futuro aumenta el número de fuentes de datos, evitaría tener una única tarea de Airbyte que se encargue de todas las ingestas. En su lugar, crearía una tarea independiente para cada fuente, de manera que puedan ejecutarse en paralelo. Una vez hayan terminado todas las ingestas correctamente, se ejecutaría dbt para transformar los datos. Así sería más fácil ver qué fuente ha fallado, detectar problemas y aprovechar mejor la ejecución en paralelo, sin tener que detener todo el proceso por un fallo en una única fuente.



