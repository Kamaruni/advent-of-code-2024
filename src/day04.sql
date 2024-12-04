\i src/prelude.sql
copy raw_lines (line) from '../input/day04.txt';

with chars as(
    select regexp_split_to_array(line, '') as line_entries
    from raw_lines
),
matrix as (
    select
        row_number() over () as row,
        generate_subscripts(line_entries, 1) as col,
        unnest(line_entries) as char
    from chars
),
entries_with_neighbors as(
    select
        this.row as row,
        this.col as col,
        this.char as char,
        other.char as other_char,
        other.row as other_row,
        other.col as other_col
    from matrix as this
    join matrix as other
    on (this.row = other.row and abs(this.col - other.col) = 1)
    or (this.row = other.row - 1 and abs(this.col - other.col) <= 1)
    or (this.row = other.row + 1 and abs(this.col - other.col) <= 1)
),
xmas as (
    select distinct *
    from (
        select
            x.row as x_row, x.col as x_col,
            m.row as m_row, m.col as m_col,
            a.row as a_row, a.col as a_col,
            s.row as s_row, s.col as s_col,
            x.row - m.row as xm_row_diff, x.col - m.col as xm_col_diff,
            m.row - a.row as ma_row_diff, m.col - a.col as ma_col_diff,
            a.row - s.row as as_row_diff, a.col - s.col as as_col_diff
        from entries_with_neighbors as x
        join entries_with_neighbors as m
        on x.char = 'X'
        and m.char = 'M' and x.other_row = m.row and x.other_col = m.col
        join entries_with_neighbors as a
        on a.char = 'A' and m.other_row = a.row and m.other_col = a.col
        join entries_with_neighbors as s
        on s.char = 'S' and a.other_row = s.row and a.other_col = s.col
    ) as xmas
),
part_one as (
    select count(*) as solution
    from xmas
    where xm_row_diff = ma_row_diff
    and ma_row_diff = as_row_diff
    and xm_col_diff = ma_col_diff
    and ma_col_diff = as_col_diff
),
cross_mas as (
    select distinct *
    from (
        select
            m.row as m_row, m.col as m_col,
            a.row as a_row, a.col as a_col,
            s.row as s_row, s.col as s_col,
            m.row - a.row as ma_row_diff, m.col - a.col as ma_col_diff,
            a.row - s.row as as_row_diff, a.col - s.col as as_col_diff
        from entries_with_neighbors as m
        join entries_with_neighbors as a
        on m.char = 'M'
        and a.char = 'A' and m.other_row = a.row and m.other_col = a.col
        join entries_with_neighbors as s
        on s.char = 'S' and a.other_row = s.row and a.other_col = s.col
    ) as cross_xmas
),
part_two as (
    select a_row, a_col
    from cross_mas
    where ma_row_diff = as_row_diff and abs(ma_row_diff) = 1 and abs(as_row_diff) = 1
    and ma_col_diff = as_col_diff and abs(ma_col_diff) = 1 and abs(as_col_diff) = 1
    group by a_row, a_col
    having count(*) = 2
)
select count(*)
from part_two
