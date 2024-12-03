\i src/prelude.sql
copy raw_lines (line) from '../input/day03.txt';

with recursive instruction_parts as (
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
results as (
    select
        instructions.*,
        true as execute,
        cast(null as int) as result
    from instructions
    where instruction_no = 0
    union all
    select
        instructions.*,
        case instructions.instruction
            when 'do' then true
            when 'don''t' then false
            else results.execute
        end as execute,
        instructions.lhs * instructions.rhs as result
    from instructions, results
    where instructions.instruction_no = results.instruction_no + 1
)
select
    sum(result) as soltution_part_1,
    sum(result) filter (where execute) as solution_part_2
from results;
