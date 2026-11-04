# Primer Impacto — dbt

Este proyecto transforma los datos crudos cargados por Airbyte en PostgreSQL
y crea modelos de staging, una dimensión unificada de puntos de venta y una
tabla de hechos incremental de visitas.

## Arquitectura

Airbyte carga los ficheros CSV en el esquema `raw` de la base de datos
PostgreSQL `primer_impacto`. Después, dbt lee esas tablas crudas, las limpia
y crea los modelos analíticos.


## Capas de dbt

### Staging

La capa `staging` contiene un .sql y .yml por cada fuente cruda:

- `stg_workers`
- `stg_visits`
- `stg_routes`
- `stg_projects`
- `stg_campaigns`
- `stg_pos_omni`
- `stg_pos_gi`

Estos modelos realizan las siguientes tareas:

- Convierten identificadores a tipos numéricos cuando procede.
- Convierten fechas a `DATE`.
- Eliminan espacios iniciales, finales y duplicados en campos de texto.
- Normalizan texto a mayúsculas cuando mejora la consistencia.
- Eliminan acentos en campos como la provincia.
- Convierten valores booleanos textuales, como `True` y `False`, a `BOOLEAN`.
- Convierten cadenas vacías en `NULL` mediante `nullif()`.
- Excluyen registros que no cumplen las reglas de obligatoriedad definidas.

Las decisiones de limpieza están comentadas dentro de cada modelo `stg_*.sql`.

### Marts

La capa `marts` contiene los modelos analíticos:

- `dim_pos_unified`: dimensión unificada de puntos de venta procedentes
  de los sistemas OMNI y GI.
- `fct_visits`: tabla de hechos incremental con las visitas a puntos de venta.

## Dimensión unificada de puntos de venta

`dim_pos_unified` concilia los puntos de venta de OMNI y GI.

### Reglas de correspondencia

La correspondencia se realiza con las siguientes reglas, en este orden:

1. **Nombre normalizado + código postal** (`NAME_AND_ZIP`).
2. **Nombre normalizado + ciudad/localidad** (`NAME_AND_CITY`), aplicada solo
   a registros que no se han emparejado mediante código postal.

El nombre se normaliza eliminando espacios duplicados y convirtiéndolo
a mayúsculas. El código postal se trata como texto para conservar
los ceros iniciales.


## Modelo incremental

`fct_visits` está materializado como incremental:

```sql
{{ config(
    materialized='incremental',
    unique_key='visit_id',
    incremental_strategy='delete+insert'
) }}
```

La estrategia es la siguiente:

1. En la primera ejecución, dbt crea la tabla y procesa todas las visitas.
2. En ejecuciones posteriores, dbt obtiene la fecha máxima de `updated_at`
   ya cargada en `fct_visits`.
3. Solo se procesan las visitas cuyo `updated_at` sea posterior o igual
   a esa fecha.
4. Para cada `visit_id` procesado, dbt elimina la versión anterior
   y inserta la versión actualizada.

Esto permite procesar visitas nuevas y visitas modificadas sin volver a
procesar todo el histórico en cada ejecución.

## Macro personalizada

La macro `remove_accents()` elimina acentos de una columna de texto.
Se utiliza en el staging para normalizar provincias.

La macro está definida en `macros/remove_accents.sql` y puede reutilizarse
en cualquier modelo que necesite normalizar texto con acentos.

## Tests de dbt

El proyecto incluye tests estándar y personalizados.

### Tests estándar

- `not_null`: comprueba que las columnas obligatorias no contengan nulos.
- `unique`: comprueba que las claves primarias no estén duplicadas.
- `relationships`: comprueba que las claves foráneas existan en la tabla
  relacionada.
- `accepted_values`: comprueba que una columna solo contenga valores
  permitidos.

### Tests personalizados

- `assert_no_duplicate_matched_pos.sql`: comprueba que no existan puntos
  de venta emparejados más de una vez en `dim_pos_unified`.
- `assert_pos_coordinates_valid.sql`: comprueba que las latitudes estén
  entre -90 y 90 y las longitudes entre -180 y 180.


## Qué añadiría con más tiempo

- Un diccionario maestro de provincias y puntos de venta.
- Matching aproximado mediante distancia de edición o similitud de texto.
- Una puntuación de confianza para los emparejamientos de puntos de venta.
- Tests adicionales de rangos de fechas, por ejemplo que `updated_at`
  no sea anterior a `created_at`.
- Alertas cuando fallen tests críticos de calidad de datos.
