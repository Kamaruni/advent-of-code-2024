\i src/prelude.sql
copy raw_lines (line) from '../input/day06.txt';

-- insert into raw_lines(line) values
-- ('....#.....'),
-- ('.........#'),
-- ('......#...'),
-- ('..#...^...'),
-- ('.......#..'),
-- ('..........'),
-- ('.#........'),
-- ('........#.'),
-- ('#.........'),
-- ('......#...');

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

create type movement as (row int, col int, item text, direction text, step integer, moved boolean);

create or replace function solvePart2() returns bigint as $$
declare
    original_map text[][];
    start_row int;
    start_col int;
    last_movement movement;
    next_movement movement;
    exited_map boolean;
    next_row int;
    next_col int;
    next_item text;
    next_direction text;
begin
    raise info 'start calculation';

    original_map = (
        select array_agg(regexp_split_to_array(line, ''))
        from raw_lines
    );

    start_row = (select line_no from raw_lines where line like '%^%');
    start_col = (select position('^' in line) from raw_lines where line like '%^%');

    create temporary table movements
    (row int, col int, item text, direction text, step bigint, moved boolean)
    on commit drop;

    last_movement = (start_row, start_col, '^', 'up', 1, true);
    insert into movements select (last_movement).*;

    exited_map = false;
    while not exited_map loop
        raise info '%', last_movement.direction;

        next_row = case last_movement.direction
            when 'up' then last_movement.row - 1
            when 'down' then last_movement.row + 1
            else last_movement.row
        end;

        next_col = case last_movement.direction
            when 'left' then last_movement.col - 1
            when 'right' then last_movement.col + 1
            else last_movement.col
        end;

        next_item = original_map[next_row][next_col];
        raise info '% / % / %', next_row, next_col, next_item;

        if last_movement.step > 6000 then
            exited_map = true;
        elseif next_item = '.' then
            next_movement = (next_row, next_col, original_map[next_row][next_col], last_movement.direction, last_movement.step + 1, true);
            insert into movements select (next_movement).*;
        elseif next_item = '#' then
            next_direction = case last_movement.direction
                when 'up' then 'right'
                when 'right' then 'down'
                when 'down' then 'left'
                when 'left' then 'up'
            end;
            next_movement = (last_movement.row, last_movement.col, last_movement.item, next_direction, last_movement.step + 1, false);
            insert into movements select (next_movement).*;
        else
            exited_map = true;
        end if;

        last_movement = next_movement;
    end loop;

    return (select count(distinct (row, col)) from movements where moved);
end
$$ language plpgsql;

select * from solvePart2();
