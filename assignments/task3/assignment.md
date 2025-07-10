Bring the raw trade data (trades.csv) to the **standard schema** below, remove duplicates, and enrich it with USD prices and sector details.

| Column          | Meaning / Expected format                                                  |
|-----------------|----------------------------------------------------------------------------|
| `trade_id`      | Unique identifier of the trade (string / int)                              |
| `symbol`        | Stock ticker in UPPERCASE                                                  |
| `price`         | Executed price in original currency (float)                                |
| `currency`      | ISO-4217 code of the trade currency (e.g. USD, EUR)                        |
| `price_usd`     | Price converted to USD using the correct FX rate from fx_rates.csv (float) |
| `quantity`      | Number of shares / contracts traded (float)                                |
| `trade_time`    | Datetime of execution (`YYYY-MM-DD HH:MM:SS`, UTC)                         |
| `trader`        | Trader name, trimmed (cleaned from unnecessary whitespaces)                |
| `sector`        | sector name (symbol_sector.csv)                                            |
| `industry`      | industry name  (symbol_sector.csv)                                         |

### Tasks

1. **Format & normalise** all existing columns to match the definitions above.  
2. **Deduplicate** — drop exact row duplicates; if `trade_id` repeats, keep one record.  
3. **Add `price_usd`** — convert `price` using an external FX table (price * rate). If fx rate for the specific date is not available, use the most recent rate in the file
4. **Enrich** — join a lookup table to fill `sector` and `industry` for each `symbol`.

Output the result as a single CSV named `clean_trades.csv`.