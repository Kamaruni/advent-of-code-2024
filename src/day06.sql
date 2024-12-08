\i src/prelude.sql
copy raw_lines (line) from '../input/day06.txt';

create type movement as (row int, col int, item text, direction text, step bigint, moved boolean, detected_loop boolean);

create or replace function next_coordinates(
    previous_direction text,
    previous_row int,
    previous_col int,
    out next_row int,
    out next_col int
)
as $$
begin
    next_row = case previous_direction
        when 'up' then previous_row - 1
        when 'down' then previous_row + 1
        else previous_row
        end;

    next_col = case previous_direction
        when 'left' then previous_col - 1
        when 'right' then previous_col + 1
        else previous_col
    end;
end
$$ language plpgsql;

create or replace function determine_movements(
    map text[][],
    start_row int,
    start_col int
)
returns setof movement
as $$
declare
    last_movement movement;
    next_movement movement;
    exited_map boolean;
    detected_loop boolean;
    next_row int;
    next_col int;
    next_item text;
    next_direction text;
begin
    create temporary table if not exists movements
    (row int, col int, item text, direction text, step bigint, moved boolean, detected_loop boolean)
    on commit drop;

    truncate movements;

    last_movement = (start_row, start_col, '^', 'up', 1, true);
    insert into movements select (last_movement).*;

    exited_map = false;
    detected_loop = false;
    while not exited_map and not detected_loop loop
        select * from next_coordinates(last_movement.direction, last_movement.row, last_movement.col)
        into next_row, next_col;

        next_item = map[next_row][next_col];

        if next_item in ('.', '^') then
            detected_loop = exists(select 1 from movements as m where (m.direction, m.row, m.col) = (last_movement.direction, next_row, next_col));
            next_movement = (next_row, next_col, map[next_row][next_col], last_movement.direction, last_movement.step + 1, true, detected_loop);
            insert into movements select (next_movement).*;
        elseif next_item = '#' then
            next_direction = case last_movement.direction
                when 'up' then 'right'
                when 'right' then 'down'
                when 'down' then 'left'
                when 'left' then 'up'
            end;
            next_movement = (last_movement.row, last_movement.col, last_movement.item, next_direction, last_movement.step + 1, false, detected_loop);
            insert into movements select (next_movement).*;
        else
            exited_map = true;
        end if;

        last_movement = next_movement;
    end loop;

    return query select * from movements;
end
$$ language plpgsql;

-- slow - takes about 1 minute
-- the equivalent implementation with `with recursive` takes a full minute!
create or replace function solve_part_1()
returns bigint
as $$
declare
    map text[][];
    start_row int;
    start_col int;
begin
    map = (
        select array_agg(regexp_split_to_array(line, ''))
        from raw_lines
    );

    start_row = (select line_no from raw_lines where line like '%^%');
    start_col = (select position('^' in line) from raw_lines where line like '%^%');

    return (
        select count(distinct (row, col))
        from determine_movements(map, start_row, start_col)
        where moved
    );
end
$$ language plpgsql;

-- very slow - takes about 1 hour
create or replace function solve_part_2()
    returns bigint
as $$
declare
    map text[][];
    modified_map text[][];
    start_row int;
    start_col int;
    obstruction record;
    result bigint;
    curr bigint;
    total bigint;
begin
    map = (
        select array_agg(regexp_split_to_array(line, ''))
        from raw_lines
    );

    start_row = (select line_no from raw_lines where line like '%^%');
    start_col = (select position('^' in line) from raw_lines where line like '%^%');

    create temporary table original_movements
    (row int, col int, item text, direction text, step bigint, moved boolean)
    on commit drop;

    insert into original_movements
    select row, col, item, direction, step, moved from determine_movements(map, start_row, start_col);

    create temporary table potential_obstructions
    (row int, col int)
    on commit drop;

    insert into potential_obstructions
    select distinct c.next_row, c.next_col
    from original_movements as o,
    lateral (select * from next_coordinates(o.direction, o.row, o.col)) as c
    where map[c.next_row][c.next_col] = '.';

    total = (select count(*) from potential_obstructions);

    result = 0;
    curr = 0;
    for obstruction in (select * from potential_obstructions) loop
        curr = curr + 1;
	raise info 'analyzing % / % (%)', curr, total, result;
	modified_map = array_cat(map, '{}'::text[][]);
        modified_map[obstruction.row][obstruction.col] = '#';
        if (select bool_or(detected_loop) from determine_movements(modified_map, start_row, start_col)) then
            result = result + 1;
        end if;
    end loop;

    return result;
end
$$ language plpgsql;

select
    (select * from solve_part_1()) as solution_part_1,
    (select * from solve_part_2()) as solution_part_2;
