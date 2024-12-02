\i src/prelude.sql
copy raw_lines (line) from '../input/day02.txt';

with levels as (
    select report_no,
           row_number() over (partition by report_no) as element_no,
           level
    from (
        select
            row_number() over () as report_no,
            unnest(cast(string_to_array(line, ' ') as int[])) as level
        from raw_lines
    ) as individual_levels
),
level_variations as (
    select
        report_no,
        0 as omitted_element_no,
        row_number() over (partition by report_no) as element_no,
        level
    from levels
    union all
    select
        levels.report_no,
        levels.element_no,
        row_number() over (partition by levels.report_no),
        other.level
    from levels
    join levels as other
    on levels.report_no = other.report_no
    and levels.element_no <> other.element_no
    order by report_no, omitted_element_no, element_no
),
level_changes as (
    select
        report_no,
        omitted_element_no,
        level,
        level - lag(level) over (partition by report_no, omitted_element_no) as change
    from level_variations
),
analyzed_level_changes as (
    select
        report_no,
        omitted_element_no,
        array_agg(change),
        every(change > 0) as all_inc,
        every(change < 0) as all_dec,
        every(abs(change) between 1 and 3) as diff_ok
    from level_changes
    group by report_no, omitted_element_no
),
dampened_level_changes as (
    select
        report_no,
        omitted_element_no,
        (all_inc or all_dec) and diff_ok as safe
    from analyzed_level_changes
),
safe_reports as (
    select
        report_no,
        bool_or(safe) as safe
    from dampened_level_changes
    group by report_no
)
select
    (select count(*) filter (where omitted_element_no = 0 and safe) from dampened_level_changes) as solution_part_1,
    (select count(*) filter (where safe) from safe_reports) as solution_part_2;
