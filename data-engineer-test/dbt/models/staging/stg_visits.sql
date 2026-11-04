with source as (

    select
        visit_id,
        intervention_point_id,
        route_id,
        campaign_id,
        visit_date,
        visit_status,
        created_at,
        updated_at
    from {{ source('raw', 'raw_visits') }}

),

cleaned as (

    select
        -- Identificadores obligatorios: se convierten a enteros
        cast(visit_id as integer) as visit_id,
        cast(intervention_point_id as integer) as intervention_point_id,
        cast(route_id as integer) as route_id,
        cast(campaign_id as integer) as campaign_id,

        -- Fecha de la visita: obligatoria, se convierte a Date
        try_cast(visit_date as date) as visit_date,

        -- Estado obligatorio: se eliminan espacios y se convierte a mayúsculas
        upper(nullif(trim(visit_status), '')) as visit_status,

        -- Fecha de creación: opcional, pero se convierte a Date si existe
        try_cast(created_at as date) as created_at,

        -- Fecha de última actualización: obligatoria, se convierte a Date
        try_cast(updated_at as date) as updated_at

    from source

),

valid_rows as (

    select *
    from cleaned
    where visit_id is not null
      and intervention_point_id is not null
      and route_id is not null
      and campaign_id is not null
      and visit_date is not null
      and visit_status is not null
      and updated_at is not null

)

select
    visit_id,
    intervention_point_id,
    route_id,
    campaign_id,
    visit_date,
    visit_status,
    created_at,
    updated_at
from valid_rows