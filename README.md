# Advent of Code 2024

My [Advent of Code 2024](https://adventofcode.com/2024) repository, using (Postgres) SQL. Don't ask me why.

The `input` directory must contain the input data for each day in a numbered file called `dayXX.txt`, e.g. `day01.txt1`.

I am using docker compose to run PostgreSQL, it can be started with

    docker compose up -d

The individual days can be run using the `run.sh` script, e.g.

    ./run.sh src/day01.txt
