# Delivery Risk Analytics: Where Do Late Deliveries Come From?

An end-to-end analytics project on a global retailer's supply-chain data: Python cleaning and exploratory analysis, SQL Server analysis, a shipping-lane risk score, and a Power BI dashboard.

> **Status:** Step 1 (data cleaning) complete. EDA, SQL, risk score and dashboard in progress. See the [roadmap](#roadmap).

---

## Business problem

DataCo, a global retailer, delivers a large share of its orders after the promised date. This project answers five questions:

1. What share of orders arrive late, and by how many days?
2. Which shipping modes, regions, markets and product categories drive the delays?
3. Is lateness a **planning** problem (delivery promises set too tight) or an **execution** problem (shipping takes too long)?
4. How much revenue and profit sit on late orders?
5. Which shipping lanes (region × shipping mode) should operations fix first?

---

## Dataset

**Source:** [DataCo Smart Supply Chain for Big Data Analysis (Kaggle)](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

| | |
| --- | --- |
| File used | `DataCoSupplyChainDataset.csv` |
| Raw size | [X] rows × 53 columns |
| Grain | One row per **order item** (an order with 3 products has 3 rows) |
| Orders | [X] unique orders |
| Period | [start date] to [end date] |

The raw file is not included in this repo because of its size. To reproduce:

1. Download `DataCoSupplyChainDataset.csv` from the Kaggle link above.
2. Save it as `data/raw/DataCoSupplyChainDataset.csv`.
3. Run `notebooks/01_cleaning.ipynb`.

---

## Step 1: Data cleaning (`notebooks/01_cleaning.ipynb`)

### What I did and why

| # | Step | Why | Rows affected |
| --- | --- | --- | --- |
| 1 | Loaded the file with a `latin-1` fallback | The file isn't UTF-8 encoded and fails to load otherwise | — |
| 2 | Checked all required columns exist | Fails early if the source file changes | — |
| 3 | Checked missing values and duplicates | [X] exact duplicates; [columns] mostly empty | [X] |
| 4 | Confirmed the grain (item vs order) | Shipping fields are identical for every item in an order, so order counts use distinct `order_id` | — |
| 5 | Tested whether profit is item- or order-level | Profit differs between items in [X]% of multi-item orders, so profit is **summed** per order | — |
| 6 | Dropped masked, empty and personal columns | Customer email/password are placeholders; names and street address aren't needed and shouldn't sit in a public repo | 8 columns removed |
| 7 | Converted date text to datetimes | Needed for trends and time features; [X] unparsed dates | — |
| 8 | Engineered features | See table below | — |
| 9 | Validated my late flag against the dataset's own flag | Matches `Late_delivery_risk` in [X]% of rows | — |
| 10 | Set aside cancelled shipments | A cancelled shipment can't be late or on time; kept in a separate file for later analysis | [X] rows |
| 11 | Sanity-checked the numbers | No negative sales, quantities or shipping days; item total = sales − discount in [X]% of rows | — |
| 12 | Renamed columns to `snake_case` | Easier to query in SQL Server and Power BI | — |

Full step-by-step counts are in [`data/processed/cleaning_log.csv`](data/processed/cleaning_log.csv).

### Features created

| Column | Definition | Used for |
| --- | --- | --- |
| `delay_days` | Actual shipping days − scheduled days (negative = early) | How late orders are |
| `is_late` | 1 if `delay_days` > 0, else 0 | Late-delivery rate |
| `lane` | `order_region` + `shipping_mode` | Risk scoring unit |
| `order_month`, `order_year`, `order_weekday` | From the order date | Trends and seasonality |
| `profit_margin` | Item profit ÷ item sales | Profitability of late vs on-time orders |
| `is_loss` | 1 if the item made a loss | Revenue-at-risk analysis |

### Data facts after cleaning

- **[X]** order-item rows and **[X]** orders kept for analysis
- **[X]** cancelled shipment rows set aside
- **[X]%** of order items were loss-making; kept on purpose, because they're real losses, not errors

### Outputs

| File | Contents |
| --- | --- |
| `data/processed/dataco_clean.csv` | Clean, analysis-ready table |
| `data/processed/dataco_canceled.csv` | Cancelled shipments |
| `data/processed/cleaning_log.csv` | Every cleaning step with rows before and after |
| `data/processed/cleaning_notes.json` | Facts reused by later notebooks |

---

## Repository structure

```
├── data/
│   ├── raw/                 # Kaggle file goes here (not committed)
│   └── processed/           # Cleaned outputs
├── notebooks/
│   ├── 01_cleaning.ipynb
│   └── 02_eda.ipynb         # coming next
├── sql/                     # coming soon
├── powerbi/                 # coming soon
├── images/                  # charts for this README
└── README.md
```

## Tools

Python (pandas, NumPy, Matplotlib) · SQL Server · Power BI · Git/GitHub

## Roadmap

- [x] Step 1: Data cleaning
- [ ] Step 2: Exploratory analysis (late rate by mode, region, category; promised vs actual days)
- [ ] Step 3: SQL Server analysis (CTEs, window functions, order-level view)
- [ ] Step 4: Lane and category risk score; revenue at risk
- [ ] Step 5: Power BI dashboard
- [ ] Key findings and recommendations

---

**Author:** Ankit Jandial · [LinkedIn](https://www.linkedin.com/in/ankit-jandial-655300159/) · ankitjandial07@gmail.com
