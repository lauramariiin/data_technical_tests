with source as (

    select
        route_id,
        campaign_id,
        route_start_date,
        route_end_date,
        route_status,
        created_at
    from {{ source('raw', 'raw_routes') }}

),

cleaned as (

    select
        -- Identificadores obligatorios: se convierten a enteros
        cast(route_id as integer) as route_id,
        cast(campaign_id as integer) as campaign_id,

        -- Fechas obligatorias de inicio y fin de ruta: se convierten a Date
        try_cast(route_start_date as date) as route_start_date,
        try_cast(route_end_date as date) as route_end_date,

        -- Estado obligatorio: se eliminan espacios y se convierte a mayúsculas
        upper(nullif(trim(route_status), '')) as route_status,

        -- Fecha de creación: opcional
        try_cast(created_at as date) as created_at

    from source

),

valid_rows as (

    select *
    from cleaned
    where route_id is not null
      and campaign_id is not null
      and route_start_date is not null
      and route_end_date is not null
      and route_status is not null
      and route_end_date >= route_start_date

)

select
    route_id,
    campaign_id,
    route_start_date,
    route_end_date,
    route_status,
    created_at
from valid_rows
