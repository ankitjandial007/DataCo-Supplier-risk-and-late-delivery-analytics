# Delivery Risk Analytics

Why do so many orders arrive late, and where should a company fix it first?

This project analyses a global retailer's order data to find the causes of late deliveries and how much revenue they put at risk.

**Status:** Data cleaning and exploratory analysis done. SQL analysis and dashboard coming next.

## Key findings

- **57.3% of orders arrive late**, by 1.62 days on average.
- **Shipping mode is the main cause.** First Class is late on 100% of orders and Second Class on 80%, compared with 40% for Standard Class.
- **The problem is the delivery promise, not the delivery speed.** First Class promises 1 day and always takes 2. Second Class promises 2 days but takes 4, the same as Standard Class. Customers paying for faster shipping get no faster delivery.
- **Location and product don't explain it.** Late rates stay in a narrow range across regions (52.6%–60.0%) and product categories (about 56%–60%).
- **57.2% of sales (20.1M of 35.2M) are on late orders.** Profit margin is almost the same for late and on-time orders (10.6% vs 11.0%), so the real cost is customer trust and revenue at risk.

![Late-delivery rate by shipping mode](images/01_late_rate_by_mode.png)

![Promised vs actual shipping days](images/02_promised_vs_actual.png)

## Dataset

**Download:** [DataCo Smart Supply Chain dataset on Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

- After cleaning: 172,765 rows covering 62,897 orders, from January 2015 onwards
- Each row is one product in an order, so one order can have several rows
- The data file isn't in this repo because it's too large. Download it from the link above and save it in `data/raw/`.

## Step 1: Data cleaning

Notebook: `notebooks/01_cleaning.ipynb`

- Removed duplicate rows and columns that were empty or held personal customer details
- Converted dates into a proper date format
- Added new columns: how many days late each order was, and whether it was late (yes/no)
- Set cancelled orders aside, since they were never shipped
- Checked the numbers made sense (no negative sales or quantities)

## Step 2: Exploratory analysis

Notebook: `notebooks/02_eda.ipynb`

Looked at late deliveries by shipping mode, region, product category, month and customer type, compared promised vs actual delivery days, and measured how much revenue sits on late orders. All charts are in the `images/` folder.

## Tools

Python (pandas, Matplotlib) · SQL Server · Power BI

## Next steps

- [x] Clean the data
- [x] Explore the data and find patterns
- [ ] Analyse it in SQL
- [ ] Score which shipping routes are most at risk
- [ ] Build a Power BI dashboard

---

**Ankit Jandial** · [LinkedIn](https://www.linkedin.com/in/ankit-jandial-655300159/)
