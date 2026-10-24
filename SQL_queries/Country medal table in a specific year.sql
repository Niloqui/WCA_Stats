/* This script cannot be executed directly, you need to replace the folloqing parameters
 * to make it work:
@YEAR@
@COUNTRY@
*/;

/* This query can handle dual rounds */
with competitions_year as (
select *
from competitions c
where year(c.start_date) = @YEAR@
),
results_country_year_podiums as (
select r.*, 1 as round_rank
from results r 
where r.global_pos <= 3
    and r.best > 0
    and r.country_id = @COUNTRY@
    and exists (
        select 1
        from competitions_year c
        where r.competition_id = c.id
    )
    and r.round_id in (
                select ro.id 
                from rounds ro 
                where ro.linked_round_id is null
                    and ro.`number` = ro.total_number_of_rounds 
            )
union all
select *
from (
    select r.*, rank() over (partition by r.competition_id, r.event_id, r.person_id
                            order by if(average>0, average, 1999999999), if(best>0, best, 1999999999), round_id) as round_rank
    from results r 
    where r.global_pos <= 3
        and r.best > 0
        and r.country_id = @COUNTRY@
        and exists (
            select 1
            from competitions_year c
            where r.competition_id = c.id
        )
        and r.round_id in (
                    select ro.id 
                    from (select ro.*, max(ro.`number`) over (partition by ro.linked_round_id) as max_dual
                        from rounds ro 
                        where ro.linked_round_id is not null
                    ) as ro
                    where ro.max_dual = ro.total_number_of_rounds
                )
    ) as r
where round_rank = 1
),
persons_num_comps as (
select r.person_id, count(*) as num_comps
from (
    select r.person_id, r.competition_id 
    from results r 
    where r.country_id = @COUNTRY@
        and exists (
            select 1
            from competitions_year c
            where r.competition_id = c.id
        )
    group by r.person_id, r.competition_id 
    ) as r
group by r.person_id
),
persons_medals_year as (
select r.person_id, r.person_name,
    sum(case when r.global_pos = 1 then 1 else 0 end) as Ori,
    sum(case when r.global_pos = 2 then 1 else 0 end) as Argenti,
    sum(case when r.global_pos = 3 then 1 else 0 end) as Bronzi,
    count(*) as Totali,
    p.num_comps as Gare
from results_country_year_podiums as r,
    competitions_year as c,
    persons_num_comps as p
where r.country_id = 'Italy'
    and r.competition_id = c.id
    and r.person_id = p.person_id
group by r.person_id, r.person_name
)
select t.*
from (
    select rank() over (order by Ori desc, Argenti desc, Bronzi desc) as rankk,
        person_id, person_name,
        Ori, Argenti, Bronzi, Totali, Gare,
        Totali / Gare as Medaglie_per_gara,
        rank() over (order by Totali / Gare desc) as rank_ratio
    from persons_medals_year as r
    order by rankk, rank_ratio, person_id
    ) as t




