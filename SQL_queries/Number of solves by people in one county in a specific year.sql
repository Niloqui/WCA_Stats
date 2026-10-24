/* This script cannot be executed directly, you need to replace the folloqing parameters
 * to make it work:
@YEAR@
@COUNTRY@
*/;

with persons_solves_comps as (
        select r.person_id, r.person_name,
        sum(if(ra.value > 0, 1, 0)) as num_solves,
        sum(if(ra.value = -1, 1, 0)) as num_DNF,
        count(distinct c.id) as num_competitions
    from results as r, competitions as c, result_attempts as ra
    where r.country_id = @COUNTRY@
        and r.id = ra.result_id
        and r.competition_id = c.id
        and year(c.start_date) = @YEAR@
    group by r.person_id
)
select rank() over (order by r.num_solves desc) as rankk,
    r.person_id, r.person_name, r.num_solves, r.num_DNF, r.num_solves + r.num_DNF as total_attempts,
    '|',
    r.num_competitions, r.num_solves / r.num_competitions as num_solves_per_comp,
    rank() over (order by r.num_solves / r.num_competitions desc) as rank_solves_comp
from persons_solves_comps as r
order by rankk, r.person_id