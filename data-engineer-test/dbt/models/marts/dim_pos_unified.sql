with omni as (

    select
        intervention_point_id as omni_id,
        intervention_point_code as omni_code,
        intervention_point_name as normalized_name,
        intervention_point_locality as normalized_city,
        intervention_point_postal_code as normalized_zip,
        intervention_point_province,
        intervention_point_latitude,
        intervention_point_longitude,
        intervention_point_is_active as omni_is_active
    from {{ ref('stg_pos_omni') }}

),

gi as (

    select
        ext_id as gi_ext_id,
        point_name as normalized_name,
        address_city as normalized_city,
        address_zip as normalized_zip,
        is_active as gi_is_active
    from {{ ref('stg_pos_gi') }}

),

/*
    Regla 1: Coincidencia exacta entre el nombre normalizado
    ('intervention_point_code' en 'pos_omni' y 'point_name' en 'pos_gi')
    y el código postal ('intervention_point_postal_code' y 'address_zip').

    Es la regla más fiable, ya que combinar ambos campos reduce
    la ambigüedad y el riesgo de falsos positivos.
*/
matched_by_zip as (

    select
        o.omni_id,
        o.omni_code,
        g.gi_ext_id,
        o.normalized_name,
        o.normalized_city,
        o.normalized_zip,
        o.intervention_point_province,
        o.intervention_point_latitude,
        o.intervention_point_longitude,
        o.omni_is_active,
        g.gi_is_active,
        'NAME_AND_ZIP' as match_rule
    from omni o
    inner join gi g
        on o.normalized_name = g.normalized_name
       and o.normalized_zip = g.normalized_zip

),

/*
    Regla 2: Coincidencia exacta entre el nombre normalizado
    ('intervention_point_code' en 'pos_omni' y 'point_name' en 'pos_gi')
    y la localidad ('intervention_point_locality' y 'address_city').

    Solo se aplica a registros que no se han emparejado por codigo postal.
*/
matched_by_city as (

    select
        o.omni_id,
        o.omni_code,
        g.gi_ext_id,
        o.normalized_name,
        o.normalized_city,
        o.normalized_zip,
        o.intervention_point_province,
        o.intervention_point_latitude,
        o.intervention_point_longitude,
        o.omni_is_active,
        g.gi_is_active,
        'NAME_AND_CITY' as match_rule
    from omni o
    inner join gi g
        on o.normalized_name = g.normalized_name
       and o.normalized_city = g.normalized_city
    where o.omni_id not in (
        select omni_id from matched_by_zip
    )
    and g.gi_ext_id not in (
        select gi_ext_id from matched_by_zip
    )

),

all_matches as (

    select * from matched_by_zip
    union all
    select * from matched_by_city

),

/*
    OMNI sin match en GI.
*/
omni_only as (

    select
        o.omni_id,
        o.omni_code,
        cast(null as varchar) as gi_ext_id,
        o.normalized_name,
        o.normalized_city,
        o.normalized_zip,
        o.intervention_point_province,
        o.intervention_point_latitude,
        o.intervention_point_longitude,
        o.omni_is_active,
        cast(null as boolean) as gi_is_active,
        cast(null as varchar) as match_rule
    from omni o
    where o.omni_id not in (
        select omni_id from all_matches
    )

),

/*
    GI sin match en OMNI.
*/
gi_only as (

    select
        cast(null as integer) as omni_id,
        cast(null as varchar) as omni_code,
        g.gi_ext_id,
        g.normalized_name,
        g.normalized_city,
        g.normalized_zip,
        cast(null as varchar) as intervention_point_province,
        cast(null as double) as intervention_point_latitude,
        cast(null as double) as intervention_point_longitude,
        cast(null as boolean) as omni_is_active,
        g.gi_is_active,
        cast(null as varchar) as match_rule
    from gi g
    where g.gi_ext_id not in (
        select gi_ext_id from all_matches
    )

),

unified as (

    select * from all_matches
    union all
    select * from omni_only
    union all
    select * from gi_only

),


final as (

    select
        -- Clave maestra del punto de venta
        coalesce(
            cast(omni_id as varchar),
            gi_ext_id
        ) as pos_key,

        omni_id,
        gi_ext_id,
        omni_code,
        normalized_name,
        normalized_city,
        normalized_zip,
        intervention_point_province,
        intervention_point_latitude,
        intervention_point_longitude,

        -- Estado del match
        case
            when omni_id is not null and gi_ext_id is not null
                then 'MATCHED'
            when omni_id is not null
                then 'OMNI_ONLY'
            else 'GI_ONLY'
        end as match_status,

        -- Regla utilizada, si existe match
        match_rule,

        -- Origen del registro
        case
            when omni_id is not null and gi_ext_id is not null
                then 'OMNI+GI'
            when omni_id is not null
                then 'OMNI'
            else 'GI'
        end as source_system,

        omni_is_active,
        gi_is_active,

        -- Estado consolidado: si alguna fuente lo marca activo, se considera activo
        coalesce(omni_is_active, gi_is_active) as is_active

    from unified

)

select
    pos_key,
    omni_id,
    gi_ext_id,
    normalized_name,
    normalized_city,
    normalized_zip,
    intervention_point_province,
    intervention_point_latitude,
    intervention_point_longitude,
    match_status,
    match_rule,
    source_system,
    omni_is_active,
    gi_is_active,
    is_active
from final