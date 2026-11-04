with source as (

    select
        campaign_id,
        project_id,
        campaign_name,
        campaign_start_date,
        campaign_end_date,
        total_visits_planned,
        created_at,
        updated_at
    from {{ source('raw', 'raw_campaigns') }}

),

cleaned as (

    select
        -- Identificadores obligatorios: se convierten a enteros
        cast(campaign_id as integer) as campaign_id,
        cast(project_id as integer) as project_id,

        -- Nombre opcional: se eliminan espacios
        nullif(trim(campaign_name), '') as campaign_name,

        -- Fechas obligatorias de la campaña: se convierten a Date
        try_cast(campaign_start_date as date) as campaign_start_date,
        try_cast(campaign_end_date as date) as campaign_end_date,

        -- Visitas planificadas obligatorias: se convierten a enteros
        cast(total_visits_planned as integer) as total_visits_planned,

        -- Fechas opcionales: se convierten a Date
        try_cast(created_at as date) as created_at,
        try_cast(updated_at as date) as updated_at

    from source

),

valid_rows as (

    select *
    from cleaned
    where campaign_id is not null
      and project_id is not null
      and campaign_start_date is not null
      and campaign_end_date is not null
      and total_visits_planned is not null
      and campaign_end_date >= campaign_start_date
)

select
    campaign_id,
    project_id,
    campaign_name,
    campaign_start_date,
    campaign_end_date,
    total_visits_planned,
    created_at,
    updated_at
from valid_rows