{{ config(
    materialized='incremental',
    unique_key='visit_id',
    incremental_strategy='delete+insert'
) }}

with visits as (
    select
            visit_id,
            intervention_point_id,
            route_id,
            campaign_id,
            visit_date,
            visit_status,
            created_at,
            updated_at
        from {{ ref('stg_visits') }}

        {% if is_incremental() %}

        /*
            Para procesar solo visitas nuevas o
            modificadas desde la última carga.
        */
        where updated_at >= (
            select coalesce(max(updated_at), '1900-01-01')
            from {{ this }}
        )

    {% endif %}

),

select
    visit_id,
    intervention_point_id,
    route_id,
    campaign_id,
    visit_date,
    visit_status,
    created_at,
    updated_at
from visits