select
    pos_key,
    intervention_point_latitude,
    intervention_point_longitude
from {{ ref('dim_pos_unified') }}
where intervention_point_latitude is not null
  and intervention_point_longitude is not null
  and (
      intervention_point_latitude not between -90 and 90
      or intervention_point_longitude not between -180 and 180
  )