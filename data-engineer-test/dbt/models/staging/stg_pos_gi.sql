with source as (

    select
        ext_id,
        point_name,
        address_street,
        address_number,
        address_city,
        address_zip,
        is_active
    from {{ source('raw', 'pos_gi') }}

),

cleaned as (

    select
        -- Identificador externo obligatorio del punto de venta
        nullif(trim(ext_id), '') as ext_id,

        -- Nombre obligatorio: se eliminan espacios y se pone en mayúsculas
        upper(nullif(
            regexp_replace(trim(point_name), '\s+', ' ', 'g'),
            ''
        )) as point_name,

        -- Dirección de la calle obligatorio: se eliminan espacios
        nullif(trim(address_street), '') as address_street,

        -- Dirección del número de calle obligatorio:
        nullif(trim(address_number), '') as address_number,

        -- Dirección de la ciudad obligatorio: se eliminan espacios
        nullif(trim(address_city), '') as address_city,

        -- Código postal obligatorio: texto para conservar ceros iniciales
        nullif(trim(address_zip), '') as address_zip,

        -- Estado activo convertido a booleano: 'True'/'False'
        case
            when lower(trim(is_active)) = 'true' then true
            when lower(trim(is_active)) = 'false' then false
            else null
        end as is_active

    from source

),

valid_rows as (

    select *
    from cleaned
    where ext_id is not null
      and point_name is not null
      and address_street is not null
      and address_number is not null
      and address_city is not null
      and address_zip is not null

)

select
    ext_id,
    point_name,
    address_street,
    address_number,
    address_city,
    address_zip,
    is_active
from valid_rows