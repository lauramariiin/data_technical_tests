with source as (

    select
        employee_id,
        employee_first_name,
        employee_active_status,
        employee_address_province,
        employee_contract_type,
        created_at
    from {{ source('raw', 'raw_workers') }}

),

cleaned as (

    select
        -- Identificador obligatorio: debe ser entero y positivo
        cast(employee_id as integer) as employee_id,

        -- Nombre obligatorio: se eliminan espacios y se conserva el formato original
        nullif(trim(employee_first_name), '') as employee_first_name,

        -- Estado convertido a booleano: 'True'/'False'
        case
            when lower(trim(employee_active_status)) = 'true' then true
            when lower(trim(employee_active_status)) = 'false' then false
            else null
        end as employee_active_status,

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
                    when contains(trim(employee_address_province), ',')
                        then concat_ws(
                            ' ',
                            trim(split_part(trim(employee_address_province), ',', 2)),
                            trim(split_part(trim(employee_address_province), ',', 1))
                        )

                    when contains(trim(employee_address_province), '/')
                        then split_part(trim(employee_address_province), '/', 1)

                    else trim(employee_address_province)
                end"
            ) }}
        ) as employee_address_province,

        -- Tipo de contrato obligatorio: se eliminan espacios y se convierte a mayúsculas
        upper(nullif(trim(employee_contract_type), '')) as employee_contract_type,

        -- Fecha: Se convierte el valor a tipo Date
        try_cast(created_at as date) as created_at
   
    from source

),

valid_rows as (

    select *
    from cleaned
    where employee_id is not null
      and employee_first_name is not null
      and employee_address_province is not null
      and employee_contract_type is not null

)

select
    employee_id,
    employee_first_name,
    employee_active_status,
    employee_address_province,
    employee_contract_type,
    created_at
from valid_rows