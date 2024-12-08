\i src/prelude.sql
copy raw_lines (line) from '../input/day08.txt';

with grid as (
    select
        line_no as row,
        col,
        frequency
    from raw_lines,
    lateral regexp_split_to_table(line, '') with ordinality vals(frequency, col)
),
paired_antennas as (
    select
        first.row as first_row,
        first.col as first_col,
        second.row as second_row,
        second.col as second_col,
        first.row - second.row as row_diff,
        first.col - second.col as col_diff
    from grid as first
    join grid as second
    on first.frequency <> '.'
    and first.frequency = second.frequency
    and (first.row, first.col) <> (second.row, second.col)
),
potentional_antinodes as (
    select distinct
        first_row + row_diff as row,
        first_col + col_diff as col,
        row_diff,
        col_diff
    from paired_antennas
),
simple_antinodes as (
    select *
    from potentional_antinodes
    where row > 0 and col > 0
    and row <= (select max(row) from grid)
    and col <= (select max(col) from grid)
),
advanced_antinodes as (
    select g.row, g.col
    from grid as g
    join simple_antinodes as a
    on (g.row - a.row) % a.row_diff = 0
    and (g.col - a.col) % col_diff = 0
    and (g.row - a.row) / a.row_diff = (g.col - a.col) / col_diff
    union all
    select first_row, first_col
    from paired_antennas
)
select
    (select count(distinct (row, col)) from simple_antinodes) as solution_part_1,
    (select count(distinct (row, col)) from advanced_antinodes) as solution_part_2;
