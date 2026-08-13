# Database Container (TimescaleDB / PostgreSQL)

Database component for storing market data, orderbook snapshots, candles, and trading logs.

## Component Structure
- `init/`: Database initialization SQL scripts (schema creation, hypertables)
- `config/`: Database configuration files (`postgresql.conf`)
- `Dockerfile`: Custom TimescaleDB image configuration
