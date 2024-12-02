\i src/prelude.sql
copy raw_lines (line) from '../input/day02.txt';

with levels as (
    select
        row_number() over () as report_no,
        unnest(cast(string_to_array(line, ' ') as int[])) as level
    from raw_lines
), level_changes as (
    select
        report_no,
        level,
        lead(level) over (partition by report_no) - level as change
    from levels
), analyzed_level_changes as (
    select
        report_no,
        array_agg(change),
        every(change > 0) as all_inc,
        every(change < 0) as all_dec,
        every(abs(change) between 1 and 3) as diff_ok
    from level_changes
    group by report_no
)
select count(*) as safe
from analyzed_level_changes
where (all_inc or all_dec) and diff_ok;
