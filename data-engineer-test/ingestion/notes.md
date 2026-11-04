
# Phase 1 — Ingestion (/ingestion)
La capa de ingesta se centra exclusivamente en extraer y cargar los datos de origen.En esta fase no se realizan transformaciones ni procesos de limpieza de datos.

### Archivos:
- 'airbyte.yaml' -> Define las 7 fuentes, el destino y las conexiones
- 'apply.py' -> Lee 'airbyte.yaml' y configura los recursos en airbyte. *Este archivo no lo he desarrollado*




## AIRBYTE.YAML

En este archivo la configuración utiliza una sección de valores default compartidos para evitar duplicar los ajustes comunes entre las siete fuentes. Entonces cada fuente solo necesita declarar su nombre y el nombre del archivo CSV. Así se facilita el mantenimiento de la configuración permitiendo actualizar los ajustes compartidos desde un único lugar.

#### Fuentes
Los 7 archivos CSV se ingieren de forma independiente y cada archivo se configura como una fuente independiente.

#### Destino
Todos los archivos tiene el mismo destino:
database: primer_impacto
schema: raw
Cada fuente se conecta de forma independiente a este destino mediante su propia conexión de Airbyte.

#### Estrategia de sincronización
Las 7 fuentes usan la misma estrategia de sincronización:
sync_mode: full_refresh
destination_sync_mode: overwrite

He escogido esta estrategia de sincronización ya que los archivos no son muy grandes y es aceptable procesarlos cada vez. Además, el conector File de Airbyte no admite la sincronización incremental. El uso de Full Refresh garantiza que cada sincronización procese el archivo de origen completo y el Overwrite que los registros anteriores se sustituyan en lugar de duplicarse cuando se vuelve a ejecutar una sincronización.
