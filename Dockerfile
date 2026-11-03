FROM timescale/timescaledb:latest-pg15

COPY ddl/ /docker-entrypoint-initdb.d/
