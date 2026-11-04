with source as (

    select
        intervention_point_id,
        intervention_point_code,
        intervention_point_name,
        intervention_point_address,
        intervention_point_province,
        intervention_point_locality,
        intervention_point_postal_code,
        intervention_point_latitude,
        intervention_point_longitude,
        intervention_point_is_active,
        created_at,
        updated_at
    from {{ source('raw', 'pos_omni') }}

),

cleaned as (

    select
        -- Identificador obligatorio del punto de venta: se convierten a enteros
        cast(intervention_point_id as integer) as intervention_point_id,

        -- Código opcional del punto de venta: se eliminan espacios
        nullif(trim(intervention_point_code), '') as intervention_point_code,

        -- Nombre obligatorio: se eliminan espacios y se pone en mayúsculas
        upper(nullif(
            regexp_replace(trim(intervention_point_name), '\s+', ' ', 'g'),
            ''
        )) as intervention_point_name,
        
        -- Dirección opcional: se eliminan espacios
        nullif(trim(intervention_point_address), '') as intervention_point_address,

        /*
            Normalización de provincia:
            1. Si contiene '/', conservar solo la primera parte
            2. Si contiene ',', invertir el orden y quitar la coma: 'Palmas, Las' -> 'Las Palmas'
            3. Quitar acentos con la macro remove_accents()
            4. Convertir a mayúsculas
            Estaria bien establecer gobernanza de datos y detallar un diccionario maestro de provincias
        */
        upper(
            {{ remove_accents(
                "case
                    when contains(trim(intervention_point_province), ',')
                        then concat_ws(
                            ' ',
                            trim(split_part(trim(intervention_point_province), ',', 2)),
                            trim(split_part(trim(intervention_point_province), ',', 1))
                        )

                    when contains(trim(intervention_point_province), '/')
                        then split_part(trim(intervention_point_province), '/', 1)

                    else trim(intervention_point_province)
                end"
            ) }}
        ) as intervention_point_province,

        -- Localidad opcional: se eliminan espacios
        nullif(trim(intervention_point_locality), '') as intervention_point_locality,

        -- Código postal opcional: se mantiene como texto para no perder ceros iniciales y se eliminan espacios
        nullif(trim(intervention_point_postal_code), '') as intervention_point_postal_code,

        -- Coordenadas obligatorias en conjuntose convierten a double
        try_cast(intervention_point_latitude as double) as intervention_point_latitude,
        try_cast(intervention_point_longitude as double) as intervention_point_longitude,

        -- Estado activo convertido a booleano: 'True'/'False'
        case
            when lower(trim(intervention_point_is_active)) = 'true' then true
            when lower(trim(intervention_point_is_active)) = 'false' then false
            else null
        end as intervention_point_is_active,

        -- Fechas opcionales: se convierten a Date
        try_cast(created_at as date) as created_at,
        try_cast(updated_at as date) as updated_at

    from source

),

valid_rows as (

    select *
    from cleaned
    where intervention_point_id is not null
      and intervention_point_name is not null
      and intervention_point_province is not null
      and intervention_point_latitude is not null
      and intervention_point_longitude is not null
      

)

select
    intervention_point_id,
    intervention_point_code,
    intervention_point_name,
    intervention_point_address,
    intervention_point_province,
    intervention_point_locality,
    intervention_point_postal_code,
    intervention_point_latitude,
    intervention_point_longitude,
    intervention_point_is_active,
    created_at,
    updated_at
from valid_rows