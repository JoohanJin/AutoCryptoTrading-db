# Database Container (TimescaleDB / PostgreSQL)

Database component for storing market data, orderbook snapshots, candles, signals, and trade execution logs.

## Component Structure
- `ddl/`: Database Data Definition Language (DDL) scripts automatically executed on container initialization (`/docker-entrypoint-initdb.d/`)
- `config/`: Database engine configuration files (`postgresql.conf`)
- `Dockerfile`: Custom TimescaleDB image configuration
