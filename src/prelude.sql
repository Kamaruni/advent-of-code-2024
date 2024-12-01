create sequence if not exists sq_line_no;
alter sequence sq_line_no restart 1;

create table if not exists raw_lines(
    line_no int primary key default nextval('sq_line_no'),
    line varchar not null
);
truncate table raw_lines;
