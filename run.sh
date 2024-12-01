#!/bin/bash

docker compose exec -u postgres -w "/var/lib/postgresql" postgres bash -c "psql -c \"\i $@\""

