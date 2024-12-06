\i src/prelude.sql
copy raw_lines (line) from '../input/day05.txt';

with rules as (
    select
        split_part(line, '|', 1)::int as before,
        split_part(line, '|', 2)::int as after
    from raw_lines
    where line like '%|%'
),
page_updates as (
    select
        update_no,
        page_no,
        page::int
    from (select row_number() over () as update_no, * from raw_lines where line like '%,%') as lines,
    lateral regexp_split_to_table(line, ',') with ordinality as pages(page, page_no)
),
ranked_updates as (
    select
        update_no,
        page_no,
        page,
        (
            select count(rules.before)
            from rules
            where rules.after = current.page
              and exists(
                select 1
                from page_updates as others
                where others.update_no = current.update_no
                and rules.before = others.page
                and others.page_no <> current.page_no
            )
        ) as before_rank,
        (
            select count(rules.after)
            from rules
            where rules.before = current.page
            and exists(
                select 1
                from page_updates as others
                where others.update_no = current.update_no
                and rules.after = others.page
                and others.page_no <> current.page_no
            )
        ) as after_rank
    from page_updates as current
),
sorted_updates as (
    select *
    from ranked_updates
    order by update_no, before_rank, after_rank desc
),
corrected_updates as (
    select
        *,
        array((
            select other.page
            from sorted_updates as other
            where other.update_no = this.update_no
            order by other.before_rank, other.after_rank desc
        )) <> array(
            select other.page
            from sorted_updates as other
            where other.update_no = this.update_no
            order by other.page_no
        ) as was_reordered
    from sorted_updates as this
),
part1 as (
    select sum(page) as solution
    from corrected_updates
    where not was_reordered
    and corrected_updates.page_no = (
        select max(other.page_no) / 2 + 1
        from corrected_updates as other
        where corrected_updates.update_no = other.update_no
    )
),
part2 as (
    select sum(page) as solution
    from corrected_updates
    where was_reordered
    and corrected_updates.before_rank = (
        select max(other.before_rank) / 2
        from corrected_updates as other
        where corrected_updates.update_no = other.update_no
    )
)
select
    (select solution from part1) as solution_part_1,
    (select solution from part2) as solution_part_2;
