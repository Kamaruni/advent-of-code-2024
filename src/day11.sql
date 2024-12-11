\i src/prelude.sql
copy raw_lines (line) from '../input/day11.txt';

create or replace function next_blink(stone text)
returns text[]
as $$
declare
    length int;
begin
    length = length(stone);
    return case
        when stone = '0' then array['1']
        when length % 2 = 0 then array[substring(stone from 1 for length / 2)::bigint::text, substring(stone from length / 2 + 1)::bigint::text]
        else array[(stone::bigint * 2024)::text]
    end;
end $$ language plpgsql;

create table if not exists memoized_blinks (
    stone text,
    depth int,
    blink_count bigint,
    primary key (stone, depth)
);

create or replace function count_blinks(stone text, depth int)
returns bigint
as $$
declare
    next_blink text[];
    result bigint;
begin
    result = (select blink_count from memoized_blinks where memoized_blinks.stone = count_blinks.stone and memoized_blinks.depth = count_blinks.depth);

    if result is not null then
        return result;
    end if;

    next_blink = next_blink(stone);
    if depth = 1 then
        result = array_length(next_blink, 1);
    else
        result = (
            with results as (
                select count_blinks(next_stones, depth - 1) as length
                from unnest(next_blink) as next_stones
            )
            select sum(length) from results
        );
    end if;

    insert into memoized_blinks values (stone, depth, result);

    return result;
end $$ language plpgsql;

with stones as (
    select regexp_split_to_table(line, ' ')::text as stone
    from raw_lines
)
select
    sum(count_blinks(stone, 25)) as solution_part_1,
    sum(count_blinks(stone, 75)) as solution_part_2
from stones;
