-- ============================================================================
-- AutoCryptoTrading TimescaleDB Initialization Schema
-- ============================================================================

-- 0. Enable TimescaleDB Extension
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;


-- ============================================================================
-- 1. Market Candles (OHLCV + Microstructure Volume Indicators)
-- ============================================================================
CREATE TABLE IF NOT EXISTS market_candles (
    time            TIMESTAMPTZ      NOT NULL,
    epoch_ms        BIGINT           NOT NULL,
    symbol          VARCHAR(20)      NOT NULL,
    timeframe       VARCHAR(10)      NOT NULL, -- '1s', '1m', '5m', '1h'
    open            NUMERIC(18, 8)   NOT NULL,
    high            NUMERIC(18, 8)   NOT NULL,
    low             NUMERIC(18, 8)   NOT NULL,
    close           NUMERIC(18, 8)   NOT NULL,
    volume          NUMERIC(24, 8)   NOT NULL,
    volume_delta    NUMERIC(24, 8),            -- Taker Buy Vol - Taker Sell Vol
    cvd             NUMERIC(24, 8),            -- Cumulative Volume Delta
    ema_fast        NUMERIC(18, 8),            -- Fast EMA (e.g., 9-period)
    ema_slow        NUMERIC(18, 8),            -- Slow EMA (e.g., 21-period)
    PRIMARY KEY (time, symbol, timeframe)
);

-- Convert to TimescaleDB Hypertable
SELECT create_hypertable('market_candles', 'time', if_not_exists => TRUE);

-- Composite Index for 0.1ms reverse chronological lookup
CREATE INDEX IF NOT EXISTS idx_candles_symbol_time 
    ON market_candles (symbol, time DESC);


-- ============================================================================
-- 2. Orderbook Snapshots (Periodic L2 Book & Skew State)
-- ============================================================================
CREATE TABLE IF NOT EXISTS orderbook_snapshots (
    time            TIMESTAMPTZ      NOT NULL,
    epoch_ms        BIGINT           NOT NULL,
    symbol          VARCHAR(20)      NOT NULL,
    best_bid        NUMERIC(18, 8)   NOT NULL,
    best_ask        NUMERIC(18, 8)   NOT NULL,
    mid_price       NUMERIC(18, 8)   NOT NULL,
    micro_price     NUMERIC(18, 8),
    spread          NUMERIC(18, 8)   NOT NULL,
    obi_top5        NUMERIC(8, 4),             -- Order Book Imbalance Top 5 (-1.0 ~ 1.0)
    obi_top10       NUMERIC(8, 4),             -- Order Book Imbalance Top 10 (-1.0 ~ 1.0)
    top_bids        JSONB,                     -- Array of [[price, qty], ...]
    top_asks        JSONB                      -- Array of [[price, qty], ...]
);

-- Convert to Hypertable
SELECT create_hypertable('orderbook_snapshots', 'time', if_not_exists => TRUE);

-- Composite Index
CREATE INDEX IF NOT EXISTS idx_orderbook_symbol_time 
    ON orderbook_snapshots (symbol, time DESC);


-- ============================================================================
-- 3. Signal Logs (Strategy Signal Audit Trail: C++ -> Python)
-- ============================================================================
CREATE TABLE IF NOT EXISTS signal_logs (
    time             TIMESTAMPTZ     NOT NULL,
    epoch_ms         BIGINT          NOT NULL,
    signal_id        VARCHAR(64)     NOT NULL, -- Correlation UUID for TCA
    symbol           VARCHAR(20)     NOT NULL,
    mid_price        NUMERIC(18, 8)  NOT NULL, -- Price when signal triggered
    ob_score         NUMERIC(8, 4)   NOT NULL, -- Composite score (-1.0 ~ 1.0)
    ema_fast         NUMERIC(18, 8),
    ema_slow         NUMERIC(18, 8),
    suggested_action VARCHAR(10)     NOT NULL, -- 'BUY', 'SELL', 'HOLD'
    status           VARCHAR(20)     NOT NULL, -- 'TRIGGERED', 'FILTERED_OUT', 'EXECUTED'
    filter_reason    TEXT,                     -- Reason if filtered (e.g. 'HIGH_SPREAD', 'MAX_LEVERAGE')
    PRIMARY KEY (time, signal_id)
);

-- Convert to Hypertable
SELECT create_hypertable('signal_logs', 'time', if_not_exists => TRUE);

-- Index for TCA correlation and latest lookups
CREATE INDEX IF NOT EXISTS idx_signals_signal_id 
    ON signal_logs (signal_id);
CREATE INDEX IF NOT EXISTS idx_signals_symbol_time 
    ON signal_logs (symbol, time DESC);


-- ============================================================================
-- 4. Trade Executions (Actual Order Fill Ledger from Exchange REST API)
-- ============================================================================
CREATE TABLE IF NOT EXISTS trade_executions (
    execution_id     SERIAL          PRIMARY KEY,
    signal_id        VARCHAR(64),              -- Links directly to signal_logs.signal_id
    order_id         VARCHAR(100)    NOT NULL, -- Exchange Client Order ID
    time             TIMESTAMPTZ     NOT NULL, -- Fill timestamp in UTC
    epoch_ms         BIGINT          NOT NULL,
    symbol           VARCHAR(20)     NOT NULL,
    exchange         VARCHAR(20)     NOT NULL DEFAULT 'BINANCE',
    side             VARCHAR(10)     NOT NULL, -- 'BUY', 'SELL'
    order_type       VARCHAR(20)     NOT NULL DEFAULT 'MARKET',
    requested_price  NUMERIC(18, 8)  NOT NULL, -- Mid-price at signal time
    executed_price   NUMERIC(18, 8)  NOT NULL, -- Actual fill price from exchange
    slippage_bps     NUMERIC(10, 4),           -- ((executed - requested) / requested) * 10000
    quantity         NUMERIC(18, 8)  NOT NULL, -- Executed coin amount
    fee              NUMERIC(18, 8),
    fee_asset        VARCHAR(10),              -- 'USDT', 'BNB'
    latency_ms       INTEGER,                  -- Execution time - Signal time (Round-trip)
    realized_pnl     NUMERIC(18, 8)            -- Realized PnL upon position close
);

-- Indexes for TCA queries and trading history
CREATE INDEX IF NOT EXISTS idx_trades_signal_id 
    ON trade_executions (signal_id);
CREATE INDEX IF NOT EXISTS idx_trades_symbol_time 
    ON trade_executions (symbol, time DESC);
