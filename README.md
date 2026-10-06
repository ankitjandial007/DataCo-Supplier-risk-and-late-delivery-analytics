# DataCo Delivery Risk Analytics

Why do so many orders arrive late, and where should a company fix it first?

This project analyses a global retailer's order data to find the causes of late deliveries and how much revenue they put at risk.

**Status:** Data cleaning done. Analysis and dashboard coming next.

## Dataset

**Download:** [DataCo Smart Supply Chain dataset on Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

- About 180519 rows of order data from 2015 to 2018
- Each row is one product in an order, so one order can have several rows
- The data file isn't in this repo because it's too large. Download it from the link above.

## Step 1: Data cleaning

Notebook: `notebooks/Data Cleaning.ipynb`

What I did:

- Removed duplicate rows and columns that were empty or held personal customer details
- Converted dates into a proper date format
- Added new columns: how many days late each order was, and whether it was late (yes/no)
- Set cancelled orders aside, since they were never shipped
- Checked the numbers made sense (no negative sales or quantities)

Result: **172765 clean rows** covering **62897 orders**, saved in `processed_data`.

## Tools

Python (pandas) · SQL Server · Power BI

## Next steps

- [x] Clean the data
- [ ] Explore the data and find patterns
- [ ] Analyse it in SQL
- [ ] Score which shipping routes are most at risk
- [ ] Build a Power BI dashboard

---

**Ankit Jandial** · [LinkedIn](www.linkedin.com/in/ankit-jandial)
