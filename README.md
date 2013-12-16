# Simple Trend Trader

A simple breakout trend trader EA for the MetaTrader trading platform.

Strategy (default configuration)

Waits for a 20-day breakout (high or low). Shorts the low breakouts, goes long on the high breakouts. Exits trade when stop-loss is triggered. Stop-losses are constantly re-evaluated for open trades at twice the 10 day average true range (ATR). Lot sizes adjusted to 1% of total account free margin.

Only a single trade will be entered into in either direction for a single pair at any one time.

# What to Expect

* More small losses and fewer large gains (expect 40% drawdowns)
* Biggest gainst will be realized of large market moves
* A long-term strategy and may stay out of the market for weeks at a time.
* I won't speculate on performance (do your own backtests and forward tests!)

# Disclaimer

Use at you're own risk. I won't take any responsibility for losses against live accounts. But I'm more than happy to accept any percentage of gains :)
