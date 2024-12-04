\i src/prelude.sql
copy raw_lines (line) from '../input/day04.txt';

insert into raw_lines(line) values
('MMMSXXMASM'),
('MSAMXMSMSA'),
('AMXSXMAAMM'),
('MSAMASMSMX'),
('XMASAMXAMM'),
('XXAMMXXAMA'),
('SMSMSASXSS'),
('SAXAMASAAA'),
('MAMMMXMMMM'),
('MXMXAXMASX');

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
            s.row as s_row, s.col as s_col
        from entries_with_neighbors as x
        join entries_with_neighbors as m
        on x.char = 'X'
        and m.char = 'M' and x.other_row = m.row and x.other_col = m.col
        join entries_with_neighbors as a
        on a.char = 'A' and m.other_row = a.row and m.other_col = a.col
        join entries_with_neighbors as s
        on s.char = 'S' and a.other_row = s.row and a.other_col = s.col
    ) as xmas
)
select *
from xmas
