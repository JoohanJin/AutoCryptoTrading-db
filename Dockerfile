FROM timescale/timescaledb:latest-pg15

COPY init/ /docker-entrypoint-initdb.d/
