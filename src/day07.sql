\i src/prelude.sql
copy raw_lines (line) from '../input/day07.txt';

-- is probably correct, but does not finish for part 1 within hours
with recursive numbers as (
    select line_no,
        split_part(line, ':', 1)::bigint as test_value,
        vals.item::bigint,
        vals.item_no
    from raw_lines,
    lateral regexp_split_to_table(split_part(line, ': ', 2), ' ') with ordinality vals(item, item_no)
),
calculations as (
    select
        test_value,
        line_no,
        'o' as operator,
        item::bigint,
        1::bigint as item_no
    from numbers
    where item_no = 1
    group by line_no, test_value, item
    union all
    (
        with next_calculations as (
            select
                numbers.test_value,
                numbers.line_no,
                numbers.item as next_item,
                previous_numbers.item as previous_item,
                numbers.item_no
            from numbers, calculations as previous_numbers
            where numbers.line_no = previous_numbers.line_no
            and numbers.item_no = previous_numbers.item_no + 1
        )
        select
            test_value,
            line_no,
            '+' as operator,
            previous_item + next_item,
            item_no
        from next_calculations
        where previous_item + next_item <= test_value
        union all
        select
            test_value,
            line_no,
            '*' as operator,
            previous_item * next_item,
            item_no
        from next_calculations
        where previous_item * next_item <= test_value
    )
),
finished_calculations as (
    select * from calculations c
    where item_no = (select max(item_no) from calculations o where c.line_no = o.line_no)
    order by line_no
),
checked_test_values as (
    select line_no, test_value
    from numbers n
    where exists (select 1 from finished_calculations c where n.line_no = c.line_no and n.test_value = c.item)
    group by line_no, test_value
)
select sum(test_value)
from checked_test_values;
