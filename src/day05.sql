\i src/prelude.sql
copy raw_lines (line) from '../input/day05.txt';

insert into raw_lines(line) values
('47|53'),
('97|13'),
('97|61'),
('97|47'),
('75|29'),
('61|13'),
('75|53'),
('29|13'),
('97|29'),
('53|29'),
('61|53'),
('97|53'),
('61|29'),
('47|13'),
('75|47'),
('97|75'),
('47|61'),
('75|61'),
('47|29'),
('75|13'),
('53|13'),
(''),
('75,47,61,53,29'),
('97,61,53,29,13'),
('75,29,13'),
('75,97,47,61,53'),
('61,13,29'),
('97,13,75,29,47');

with rules as (
    select
        split_part(line, '|', 1)::int as before,
        split_part(line, '|', 2)::int as after
    from raw_lines
    where line like '%|%'
),
page_updates as (
    select
        update_no,
        page_no,
        page::int
    from (select row_number() over () as update_no, * from raw_lines where line like '%,%') as lines,
    lateral regexp_split_to_table(line, ',') with ordinality as pages(page, page_no)
),
checked_updates as (
    select
        *,
        not exists(
            select rules.before
            from rules
            join page_updates as after
            on before.update_no = after.update_no
            and after.page_no = before.page_no + 1
            and rules.before = after.page
            where rules.after = before.page
        ) as is_ordered
    from page_updates as before
),
correctly_ordered_updates as (
    select
        update_no,
        page_no,
        page,
        bool_and(is_ordered) over same_update as is_ordered,
        (max(page_no) over same_update) / 2 + 1 as middle_page_no
    from checked_updates
    window same_update as (partition by update_no rows between unbounded preceding and unbounded following)
)
select sum(page)
from correctly_ordered_updates
where middle_page_no = page_no and is_ordered;
