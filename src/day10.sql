\i src/prelude.sql
copy raw_lines (line) from '../input/day10.txt';

create or replace function is_adjacent(p0_row int, p0_col int, p1_row int, p1_col int)
returns boolean
as $$
    select (abs(p0_row - p1_row) = 1 and p0_col = p1_col)
    or (abs(p0_col - p1_col)) = 1 and p0_row = p1_row
$$ language sql;

with map as (
    select
        line_no as row,
        col::int,
        height::int
    from raw_lines,
    lateral regexp_split_to_table(line, '') with ordinality lines(height, col)
),
potential_trailheads as (
    select *
    from map
    where height = 0
),
trails as (
    select
        t.row, t.col,
        count(distinct (p9.row, p9.col)) as score,
        count(*) as rating
    from potential_trailheads as t
    join map as p1 on p1.height = 1 and is_adjacent(t.row, t.col, p1.row, p1.col)
    join map as p2 on p2.height = 2 and is_adjacent(p1.row, p1.col, p2.row, p2.col)
    join map as p3 on p3.height = 3 and is_adjacent(p2.row, p2.col, p3.row, p3.col)
    join map as p4 on p4.height = 4 and is_adjacent(p3.row, p3.col, p4.row, p4.col)
    join map as p5 on p5.height = 5 and is_adjacent(p4.row, p4.col, p5.row, p5.col)
    join map as p6 on p6.height = 6 and is_adjacent(p5.row, p5.col, p6.row, p6.col)
    join map as p7 on p7.height = 7 and is_adjacent(p6.row, p6.col, p7.row, p7.col)
    join map as p8 on p8.height = 8 and is_adjacent(p7.row, p7.col, p8.row, p8.col)
    join map as p9 on p9.height = 9 and is_adjacent(p8.row, p8.col, p9.row, p9.col)
    group by t.row, t.col
)
select
    sum(score) as solution_part_1,
    sum(rating) as solution_part_2
from trails;
