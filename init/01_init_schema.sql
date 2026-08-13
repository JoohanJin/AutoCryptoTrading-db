-- Enable TimescaleDB Extension
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Candles Table
CREATE TABLE IF NOT EXISTS market_candles (
    time TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    open NUMERIC(18, 8) NOT NULL,
    high NUMERIC(18, 8) NOT NULL,
    low NUMERIC(18, 8) NOT NULL,
    close NUMERIC(18, 8) NOT NULL,
    volume NUMERIC(24, 8) NOT NULL,
    PRIMARY KEY (time, symbol)
);

-- Convert to Hypertable
SELECT create_hypertable('market_candles', 'time', if_not_exists => TRUE);

-- Trade Logs Table
CREATE TABLE IF NOT EXISTS trade_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    symbol VARCHAR(20) NOT NULL,
    side VARCHAR(10) NOT NULL,
    price NUMERIC(18, 8) NOT NULL,
    quantity NUMERIC(18, 8) NOT NULL,
    strategy VARCHAR(50) NOT NULL
);
