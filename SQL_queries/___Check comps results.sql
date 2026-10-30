/* This script cannot be executed directly, you need to replace the folloqing parameters
 * to make it work:
@COMP_LIST@
@COMP_LIST_WITH_0@
*/;

select r.competition_id, max(conteggio) as conteggio,
    if(max(conteggio) = 0, 'No results yet', '') as res_message
from (
    select r.competition_id, count(*) as conteggio
    from results as r
    where r.competition_id in (@COMP_LIST@)
    group by r.competition_id

    union all

    select *
    from (
        values @COMP_LIST_WITH_0@
        ) as r (competition_id, conteggio)
    ) as r
group by r.competition_id
order by conteggio desc, r.competition_id

