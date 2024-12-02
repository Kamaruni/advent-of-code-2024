\i src/prelude.sql
copy raw_lines (line) from '../input/day02.txt';

insert into raw_lines(line) values
('7 6 4 2 1'),
('1 2 7 8 9'),
('9 7 6 2 1'),
('1 3 2 4 5'),
('8 6 4 4 1'),
('1 3 6 7 9'),
('16 19 21 24 21');

-- part 1
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

-- part2
with levels as (
    select
        row_number() over () as report_no,
        unnest(cast(string_to_array(line, ' ') as int[])) as level
    from raw_lines
), level_changes as (
    select
        report_no,
        level,
        level - lag(level) over (partition by report_no) as change
    from levels
), level_changes_with_outliers as (
    select
        report_no,
        level,
        change,
        (
            change < 0 and every(change > 0) over other_rows or
            change > 0 and every(change < 0) over other_rows
        ) as direction_problem,
        (
            abs(change) < 1 or abs(change) > 3
        ) as diff_problem
    from level_changes
    window other_rows as (
        partition by report_no
        rows between unbounded preceding and unbounded following exclude current row
    )
), level_changes_with_outlier_count as (
    select
        report_no,
        level,
        change,
        direction_problem,
        diff_problem,
        count(*) filter (where direction_problem or diff_problem) over(partition by report_no) as outlier_count
    from level_changes_with_outliers
), dampened_level_changes as (
    select
        report_no,
        level,
        level - lag(level) over (partition by report_no) as change
    from level_changes_with_outlier_count
    where outlier_count = 0 or (outlier_count = 1 and not direction_problem and not diff_problem)
), analyzed_dampened_level_changes as (
    select
        report_no,
        array_agg(level),
        array_agg(change),
        every(change > 0) as all_inc,
        every(change < 0) as all_dec,
        every(abs(change) between 1 and 3) as diff_ok
    from dampened_level_changes
    group by report_no
)
select * from level_changes_with_outliers;
