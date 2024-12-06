\i src/prelude.sql
copy raw_lines (line) from '../input/day06.txt';

insert into raw_lines(line) values
('....#.....'),
('.........#'),
('..........'),
('..#.......'),
('.......#..'),
('..........'),
('.#..^.....'),
('........#.'),
('#.........'),
('......#...');

with recursive map as (
    select
        line_no as row,
        col,
        item
    from raw_lines,
    lateral regexp_split_to_table(line, '') with ordinality cols(item, col)
),
movements as (
    select
        row,
        col,
        item as item,
        'up' as direction,
        1 as step,
        true as moved
    from map
    where item = '^'
    union all
    select * from (
        with previous as (
            select * from movements
        ),
        next as (
            select
                next.row,
                next.col,
                next.item,
                previous.direction as direction,
                previous.step + 1 as step,
                true as moved
            from previous as previous, map as next
            where previous.step = (select max(step) from previous)
            and (next.row, next.col) = case previous.direction
                when 'up' then (previous.row - 1, previous.col)
                when 'right' then (previous.row, previous.col + 1)
                when 'down' then (previous.row + 1, previous.col)
                when 'left' then (previous.row, previous.col - 1)
            end
        ),
        turn as (
            select
                previous.row,
                previous.col,
                previous.item,
                case previous.direction
                    when 'up' then 'right'
                    when 'right' then 'down'
                    when 'down' then 'left'
                    when 'left' then 'up'
                end as direciton,
                previous.step + 1 as step,
                false as moved
            from previous
            where previous.step = (select max(step) from previous)
        )
        select * from next where next.item <> '#'
        union all
        select * from turn where exists(select 1 from next where next.item = '#')
    ) as next
)
select count(distinct (row, col))
from movements
where moved;
