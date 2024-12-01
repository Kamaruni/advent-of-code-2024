\i src/prelude.sql
copy raw_lines (line) from '../input/day01.txt';

with left_list_ordered as (
    select cast(split_part(line, '   ', 1) as int) as left_part
    from raw_lines
    order by left_part
)
select
    row_number() over () as row_no,
    left_part
into left_list
from left_list_ordered;

with right_list_ordered as (
    select cast(split_part(line, '   ', 2) as int) as right_part
    from raw_lines
    order by right_part
)
select
    row_number() over () as row_no,
    right_part
into right_list
from right_list_ordered;

-- part 1
with diffs as (
    select
        abs(left_part - right_part) as diff
    from left_list
    join right_list
    on left_list.row_no = right_list.row_no
)
select sum(diff) as solution_part_1
from diffs;

-- part 2
with scored_list as (
    select
        left_part,
        left_part * (
            select count(*)
            from right_list
            where right_part = left_part
        ) as score
    from left_list
)
select sum(score) as solution_part_2
from scored_list;

drop table left_list;
drop table right_list;
