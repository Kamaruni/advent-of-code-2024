\i src/prelude.sql
copy raw_lines (line) from '../input/day03.txt';

with instruction_parts as (
    select
        array_remove(
            regexp_matches(line, '(mul)\((\d+),(\d+)\)|(don''t)\(\)|(do)\(\)', 'g'), null
        ) as expression
    from raw_lines
),
instructions as (
    select
        row_number() over () as instruction_no,
        expression[1] as instruction,
        cast(expression[2] as int) as lhs,
        cast(expression[3] as int) as rhs
    from instruction_parts
    union all
    select 0, 'do', null, null
),
conditional_instructions as (
    select
        instruction_no,
        instruction,
        lhs,
        rhs,
        (
            select case prev.instruction
                when 'do' then true
                when 'don''t' then false
            end
            from instructions as prev
            where prev.instruction_no <= instructions.instruction_no
            and prev.instruction in ('do', 'don''t')
            order by instruction_no desc
            limit 1
        ) as execute
    from instructions
)
select
    sum(lhs * rhs) as solution_part_1,
    sum(lhs * rhs) filter (where execute) as solution_part_2
from conditional_instructions;
