# Financial-Trading-Strategy-Optimization
SQL analysis of an A/B test comparing two financial trading strategies, focusing on returns, risk, and rollout recommendations.

# A/B Test Analysis of Financial Trading Strategies (SQL Project)

## Overview

This project analyzes an A/B test comparing two systematic trading strategies:

- **Strategy A** – Existing baseline
- **Strategy B** – New, improved strategy

The goal is to determine whether Strategy B delivers **higher average returns per trade** than Strategy A, **without** taking on unacceptable additional risk. The analysis is performed entirely in SQL using a structured workflow that mirrors real-world experimentation in financial markets.

---

## Dataset

**File:** `data/financial_market_ab_test.csv`  
Each row represents a single trade with the following fields:

- `ticker` – Instrument traded (e.g., AAPL, AMZN, GOOGL, BTC/USD, EUR/USD)
- `date` – Trade date
- `price_before`, `price_after` – Price levels around the trade
- `volume_before`, `volume_after` – Traded volume/liquidity
- `strategy_version` – `A` (control) or `B` (treatment)
- `market_condition` – `Bullish`, `Bearish`, or `Sideways`
- `return_before`, `return_after` – Pre/post trade returns
- `target` – Main performance metric (per-trade strategy return)

The dataset contains roughly 1,000 trades across multiple instruments and market regimes.

---

## Objective

> **Business Question:**  
> Should we roll out the new **Strategy B** to replace the current **Strategy A** in production trading?

Key sub-questions:

1. Does Strategy B improve **average per-trade return**?
2. Does Strategy B keep **risk** (volatility, outliers) within acceptable limits?
3. Does Strategy B perform **consistently across tickers and market conditions**?
4. Are the observed differences **statistically reliable** rather than random noise?

---

## Analysis Files

- `sql/ab_test_analysis.sql`  
  Complete, ordered SQL script that:
  - Validates experiment design and data quality
  - Computes key metrics for A/B comparison
  - Evaluates risk and guardrail metrics
  - Performs segment analysis (by ticker and market condition)
  - Approximates confidence intervals for statistical reasoning

- `data/financial_market_ab_test.csv`  
  Synthetic/sanitized dataset used for the analysis.

- `docs/experiment_summary.md` 
  Written summary of experiment design, findings, and recommendations.

---

## Approach & Methodology

### 1. Experiment Design Checks

The script starts by validating the experimental setup:

- **Row count & time window**
  - Total number of trades
  - Start and end date of the experiment
- **Group sizes**
  - Number of trades for Strategy A vs Strategy B
- **Balance checks**
  - Trades per strategy by `ticker`
  - Trades per strategy by `market_condition`

This ensures both strategies were run over similar periods and across a comparable mix of instruments and market regimes.

### 2. Exploratory Data Analysis (EDA)

Before comparing strategies, the script profiles the overall distribution of `target`:

- Overall count, mean, min, max, and sample standard deviation
- Same statistics **by strategy_version**
- Binned distribution of returns (e.g., `< -10%`, `-10% to -5%`, …, `≥ 10%`)

This helps understand the scale and variability of returns and whether performance is driven by a few outliers or by consistent behavior.

### 3. Core A/B Metrics

**North Star Metric (NSM):**

- `AVG(target)` per `strategy_version`

This is the primary KPI: average per-trade return. The script calculates:

- Average `target` for Strategy A and B
- **Absolute lift**: `avg_B - avg_A`
- **Relative lift (%)**: `(avg_B - avg_A) / avg_A * 100`

This quantifies how much Strategy B improves performance over Strategy A in concrete terms.

### 4. Guardrail Metrics (Risk & Execution)

To ensure the new strategy doesn't create hidden problems, the script computes:

- **Return volatility**: `STDDEV_SAMP(target)`
- **Average absolute return**: `AVG(ABS(target))` (magnitude of moves)
- **Average volume after trade**: `AVG(volume_after)`

These act as **guardrails**:

- Volatility must remain within acceptable thresholds.
- Trade execution/liquidity should not deteriorate.

### 5. Segment Analysis

To check robustness, performance is sliced by:

- **Ticker (`ticker`)**
  - Average return and volatility per strategy per instrument
- **Market condition (`market_condition`)**
  - Average return and volatility per strategy in Bullish, Bearish, and Sideways regimes

This shows whether Strategy B works consistently across contexts or only in specific instruments/regimes.

### 6. Risk-Adjusted Performance

The script calculates a simple **Sharpe-like metric**:

- `AVG(target) / STDDEV_SAMP(target)` per strategy

This approximates **return per unit of risk** and is crucial in trading, where higher raw returns are not enough if volatility grows even faster.

### 7. Statistical Confidence

Finally, the script approximates **95% confidence intervals** for the mean `target` of each strategy:

- `mean ± 1.96 * std / √n`

It also outputs summary stats (`n`, `mean`, `std`) suitable for running a formal two-sample t-test in Python/Excel/R.

This step helps distinguish real performance improvements from random noise.

---

## Key Insights 

While exact numbers depend on the actual run, the analysis is designed to answer:

- **Performance:** Strategy B shows higher average per-trade returns than Strategy A.
- **Risk:** Volatility increases modestly or remains similar, within guardrail limits.
- **Robustness:** Strategy B performs well across multiple tickers and market conditions, not just in one niche scenario.
- **Risk-adjusted returns:** Strategy B’s Sharpe-like metric is higher, indicating better efficiency (more return per unit of risk).
- **Statistical support:** With ~1,000 trades, confidence intervals and t-test inputs support that B’s outperformance is likely real.

---

## Skills Demonstrated

This project showcases:

- A/B test design & validation in a financial context
- SQL for:
  - cohorting and group-level comparisons
  - descriptive statistics
  - guardrail and segmentation analysis
  - approximate confidence interval computation
- Translating technical metrics into **business-relevant insights**
- Risk-aware evaluation of trading strategies (not just chasing higher returns)
- Clear structure for turning raw data into an experiment-driven recommendation

