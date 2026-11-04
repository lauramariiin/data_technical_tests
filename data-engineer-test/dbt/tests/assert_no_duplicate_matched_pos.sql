select
    omni_id,
    gi_ext_id,
    count(*) as matched_rows
from {{ ref('dim_pos_unified') }}
where match_status = 'MATCHED'
group by
    omni_id,
    gi_ext_id
having count(*) > 1