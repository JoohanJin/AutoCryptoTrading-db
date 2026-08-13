-- Enable TimescaleDB Extension
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- 1. Real-time Market Ticks Table (High Frequency)
CREATE TABLE IF NOT EXISTS market_ticks (
    time TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    price NUMERIC(18, 8) NOT NULL,
    quantity NUMERIC(18, 8) NOT NULL,
    side VARCHAR(10) NOT NULL,
    exchange VARCHAR(20) NOT NULL
);

-- Convert market_ticks to Hypertable partitioned by time
SELECT create_hypertable('market_ticks', 'time', if_not_exists => TRUE);
CREATE INDEX IF NOT EXISTS idx_market_ticks_symbol_time ON market_ticks (symbol, time DESC);

-- 2. OHLCV Candles Table
CREATE TABLE IF NOT EXISTS market_candles (
    time TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    timeframe VARCHAR(10) NOT NULL,
    open NUMERIC(18, 8) NOT NULL,
    high NUMERIC(18, 8) NOT NULL,
    low NUMERIC(18, 8) NOT NULL,
    close NUMERIC(18, 8) NOT NULL,
    volume NUMERIC(24, 8) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    PRIMARY KEY (time, symbol, timeframe, exchange)
);

-- Convert market_candles to Hypertable
SELECT create_hypertable('market_candles', 'time', if_not_exists => TRUE);

-- 3. Orderbook L2 Depth Snapshots Table
CREATE TABLE IF NOT EXISTS orderbook_snapshots (
    time TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    bids JSONB NOT NULL,
    asks JSONB NOT NULL
);

-- Convert orderbook_snapshots to Hypertable
SELECT create_hypertable('orderbook_snapshots', 'time', if_not_exists => TRUE);

-- 4. Trade Execution Logs Table
CREATE TABLE IF NOT EXISTS trade_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    symbol VARCHAR(20) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    side VARCHAR(10) NOT NULL,
    price NUMERIC(18, 8) NOT NULL,
    quantity NUMERIC(18, 8) NOT NULL,
    strategy VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    order_id VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_trade_logs_timestamp ON trade_logs (timestamp DESC);
