with source as (

    select
        project_id,
        client_code,
        project_name,
        created_at,
        updated_at
    from {{ source('raw', 'raw_projects') }}

),

cleaned as (

    select
        -- Identificador obligatorio del proyecto: se convierten a enteros
        cast(project_id as integer) as project_id,

        -- Código de cliente obligatorio: se eliminan espacios y se convierte a mayúsculas
        upper(nullif(trim(client_code), '')) as client_code,

        -- Nombre obligatorio del proyecto: se eliminan espacios
        nullif(trim(project_name), '') as project_name,

        -- Fechas opcionales: se convierten a Date
        try_cast(created_at as date) as created_at,
        try_cast(updated_at as date) as updated_at

    from source

),

valid_rows as (

    select *
    from cleaned
    where project_id is not null
      and client_code is not null
      and project_name is not null

)

select
    project_id,
    client_code,
    project_name,
    created_at,
    updated_at
from valid_rows

