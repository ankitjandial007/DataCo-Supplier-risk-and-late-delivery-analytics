# DataCo Supply Chain & Sales Analysis  

Transforming raw operational and sales data into strategic insights to optimize supply chain performance and business decisions.

---

## Introduction

This project focuses on analyzing the operational performance and sales data of **DataCo**, an e-commerce FMCG company, to derive actionable insights for improving supply chain efficiency, customer satisfaction, and revenue growth.

**Objective:**  
- Evaluate overall business performance  
- Identify supply chain bottlenecks and delivery issues  
- Analyze customer behavior and product sales patterns  
- Generate recommendations for operational and marketing strategies

---

## Dataset

### Source

The dataset was obtained from **Kaggle**:

- [DataCo Smart Supply Chain Dataset](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis?select=DataCoSupplyChainDataset.csv&fbclid=IwZXh0bgNhZW0CMTAAYnJpZBExOHpkQlRZZ2Npcms0Mm1xbQEevfLmEOE3AV266rm7x1DFe5NxkfXlWzOIZEYeNJZCOYQzpDcVUmHqk-w55NM_aem_UrGbZzRO1qdZZ5Il6uounw)

Alternatively, you can access **DataCoSupplyChainDataset.txt** via Google Drive (link in the project folder) to download the data.

### Key Columns

- `Order ID`, `Order Status`, `Order Item Quantity`, `Order Item Total`, `Order Profit Per Order`
- `Shipping Mode`, `Days for shipping (real)`, `Days for shipment (scheduled)`, `Delivery Status`, `Late_delivery_risk`
- `Customer City`, `Market`, `Category Name`
- `Order Region`, `Order State`, `shipping date (DateOrders)`
- And other supply chain and financial performance fields

---

## Tools & Technologies

- **Languages**: Python  
- **Libraries**: pandas, numpy, matplotlib, seaborn  
- **Visualization**: Tableau, Power BI, Looker Studio, D3.js  
- **Database**: Google BigQuery

---

## Project Workflow

1. **Data Understanding**:
   - Reviewed dataset structure, business context, and data dictionary.

2. **Exploratory Data Analysis (EDA)**:
   - Analyzed sales performance by market, category, region.
   - Evaluated customer purchasing behavior and top-selling products.

3. **Operational Performance Analysis**:
   - Assessed delivery time performance against SLA.
   - Identified regions, shipping modes, and products with high late delivery rates.

4. **Seasonality & Basket Analysis**:
   - Investigated seasonal sales trends.
   - Conducted market basket analysis for product bundling opportunities.

5. **Financial Performance Analysis**:
   - Analyzed revenue, cost, and profit margins by customer segment and product.

6. **Visualization Development**:
   - Built interactive dashboards using:
     - **Tableau**: [View Tableau Dashboard](https://public.tableau.com/app/profile/huan.nguyen2217/viz/DV-209TableauPublic/Story1?fbclid=IwZXh0bgNhZW0CMTAAYnJpZBExeEg5b3hOajVjWGVUTzdNRgEe5tZoQMubNqzh8m8SVauVpMgH-dDIcuVuPBBLtr_dvxXRf5p2VKxJL1-wMjA_aem_Kzvk4tTHn4Ja1C92p_seJA)  
     - **Power BI**: view via `dataco_dashboard_pbi.pbix` in this repository

7. **Insight Generation & Recommendations**:
   - Extracted key business insights and compiled actionable recommendations.  
   - *For detailed insights, read `dataco_insights_report.pdf`.*

---

## Key Insights (Preview)

- Over 54% of orders were delivered late, highlighting systemic logistics issues.  
- First Class shipping had ~95% late deliveries, requiring immediate SLA review.  
- LATAM and Europe markets generated highest revenue but had high late shipment rates.  
- Basket analysis revealed strong cross-selling opportunities within sports and fitness categories.  
- Customer spending peaked at month-end, indicating optimal promotion periods.
- For full insight breakdowns and strategic recommendations, please refer to the `dataco_insights_report.pdf` included in this repository.

---

## Learning Outcomes

- Advanced data analysis and visualization skills across multiple BI tools.  
- Ability to derive strategic supply chain insights from complex datasets.  
- Experience designing interactive dashboards for business decision-making.  
- Strengthened storytelling to communicate data-driven recommendations effectively.
