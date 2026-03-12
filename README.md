# NINOX CASE STUDY

## “Your data modeling approach and architecture decisions”

### Data modeling approach and architecture decisions:
I implemented a Medallion architecture within an ELT (Extract, Load, Transform) framework, using a layered approach in dbt to transition raw transactional data into actionable metrics. This architecture is structured into Bronze (Staging) for technical cleanup and deduplication, Silver (Intermediate) for metric calculation and enrichment, and Gold (Marts) for final business-ready reporting.
The raw dataset is structured as a Snowflake Schema. The central Fact Table (Orders) contains the financial events but lacks direct user keys, requiring a chain of joins through the Subscriptions Dimension to reach the Users Dimension (Orders--> Subscriptions-->Users) to get user count and surface geographic and plan-level segments.

**Transformation Layers in dbt:**

![dbt Lineage](https://github.com/user-attachments/assets/f67689bf-42cc-48d8-9a64-623bfe420c61)

●	**Staging Layer (stg_)**: This layer acts as a mirror of the raw CSV files. This layer handles data cleanup, removing duplicates, casting timestamp strings to proper DATE types for calculation, and parsing JSON metadata.

●	**Intermediate Layer (int_)**: 

**Joining data**: I started by combining the three datasets (orders  subscriptions  users) to get all the data in one single table (int_base). 

**Scaffolding (Data Explosion)**: Each order covers a 12-month term but is stored as a single row. To analyze revenue month by month, I “expanded” each order by combining it with a list of months (0–11), creating a continuous monthly timeline for every transaction.

**MRR Movement Logic**: Using the LAG () function, I compared monthly recurring revenue (MRR) for each customer month over month. This lets me categorize MRR into types like New, Expansion, Contraction, Lost, or Start of Period.

**Cohort Retention Logic**: To track customer stickiness, I identified the Start Month for every user using (MIN(reporting_month)). Then I calculated a age index (Month 0 to 35). This logic links multiple years of renewal orders back to the original acquisition date, giving a true picture of long-term customer value.

●	**Marts Layer (fct_)**: This layer is the final, reporting-ready stage of the data pipeline, where detailed logic is turned into structured tables ready for analysis. It includes 4 tables.
o	**fct_mrr_movements_monthly**: Summarizes revenue changes per month, showing totals for all movement types: Start of Period, New, Expansion, Contraction, Lost, and End of Period.
o	**fct_mrr_movements_reporting**: Used to visualize MRR movements. Builds on the monthly summary but keeps Users, Country and Plan details. This lets me explore revenue trends interactively by segmenting at country or plan level, and also allows me to get user count in the tool tips wherever it might be helpful.
o	**fct_mrr_cohorts_summary**: Tracks customer cohorts from their first month over a 36-month time, showing retained revenue and retention percentage for cohort analysis.
o	**fct_mrr_cohorts_reporting**: Used to visualize cohort retention. Builds on the cohort summary but keeps Country and Plan details to segment at country or plan level.

●	**Macros**: To keep the calculations consistent and the code clean I moved the key formulas into three dbt macros:
o	**calculate_net_revenue**: Converts gross revenue to net by removing tax and applying exchange rates so all revenue is standardised in EUR.
o	**calculate_mrr**: Calculates monthly recurring revenue by dividing net revenue by the fixed 12-month subscription term.
o	**to_start_of_month**: Converts any date to the first day of its month so cohort analysis and monthly reporting stay accurate.
●	**Visualization**: To clearly communicate the Ninox SaaS metrics required for this assignment, I designed a Power BI dashboard structured to move from high-level totals to granular historical trends and long-term customer behavior.

![Dashboard_Final](https://github.com/user-attachments/assets/c524369a-905a-41e6-beaf-e7d886cd9114)

**Interactive Segmentation**: To enable a microscopic view of the business, I implemented a filtering system using Year, Plan Name, and Country. While the users table was provided as optional context, I made the architectural decision to integrate it into the gold layer to fulfil the requirement of better storytelling.

**Visual Narrative Structure**: The dashboard is organized into three thematic rows to tell a complete business story:

**Row 1: Macro Performance (The Status Quo)**:
o	**KPI Cards**: Highlight the four primary components of revenue flow: New, Expansion, Lost, and Contraction MRR, allowing for an immediate pulse check on growth efficiency.
o	**MRR Trend**: A bar chart visualizing the End of Period MRR over the full 36-month timeline. I utilized conditional formatting (Green for peaks, Red for lows) to instantly signal performance outliers to leadership.
o	**Segmentation Visuals**: "MRR by Plan" and "MRR by Country" identify where the revenue density lives, revealing which product tiers and geographies act as the primary growth engines.

**Row 2: Marginal Change (The Living Story**):
o	**MRR Movements (Waterfall)**: This acts as the financial bridge between the start and end of a period, visualizing exactly how acquisition and expansion outweighed churn and contraction.
o	**MRR Movements over Time**: A stacked column chart that provides historical context to the waterfall, showing the yearly momentum of inflows and outflows.

Row 3: **Long-term Customer Value (The Stickiness Story)**:
o	**Monthly Cohort Retentio**n: A heatmap/matrix visualizing how retention for each monthly cohort varies over the span of their lifetime including renewals and churn.

**Enhanced UX**: All visuals are enriched by tooltips. In addition to displaying absolute EUR amounts, I integrated distinct user counts into the tooltips to show the user base contributing to the revenue.

## “Tools and technologies used and why you chose them”

### Tools and Technologies:
•	**BigQuery:** I have chosen BigQuery as my data warehouse because of its fast query performance and seamless integration with popular data visualization and modeling tools like powerbi and dbt. It’s also simple to use, scales well as data grows.
•	**dbt (Data Build Tool)**: To clean and model the raw CSV files, I used dbt because it makes it easy to create different models for different purposes. In my case study, I created a staging layer for cleaning the data, an intermediate layer to perform calculations and join tables, and a mart layer to generate the final output for visualization. Beyond this, dbt allows me to maintain data quality by adding multiple tests in YML files, ensuring that the data remains reliable and consistent.
Additionally, dbt integrates well with version control systems like Git, which helps track changes and maintain a clear history of code updates. By organizing the project into layers and using tests with version control, I found it much easier to manage and maintain the code over time.
•	**GitHub**: I used GitHub for code versioning, which helped me keep track of all changes and manage different versions of my project. It also served as the primary platform for submitting my work, ensuring everything is organized and easy to access.
•	**Power BI**: Power BI: To visualize the MRR movements and MRR cohort retention, I used Power BI because it allows me to create interactive and actionable dashboards, which are essential for effective data storytelling. Power BI also offers a wide range of visualization options, easy integration with data sources, and the ability to share insights seamlessly with stakeholders, making it a powerful tool for turning data into decisions.


## “Anything noteworthy you discovered in the data and how you dealt with it”

### Data Insights and Handling Strategies:
•	**Duplicate Orders**: Some rows in orders.csv had the same order_id repeated with identical details. I fixed this in the staging layer by using DISTINCT, so that the revenue wouldn’t be counted multiple times.
•	**Missing Subscription Dates**: A few records were missing start_date or end_date. I kept them in the staging layer so dbt tests could flag them, but excluded them from the monthly expansion since a full 12-month timeline couldn’t be created.
•	**License Anomaly**: Couple of customers had a subscription with 0 licenses but still paid certain amount against them. I treated the payment as valid revenue because the financial transaction is the most reliable source of truth.
•	**Null Tax Values**: Tax fields for some records in the JSON metadata were null. Instead of guessing a value, I replaced nulls with 0% to avoid incorrectly reducing reported revenue.
•	**Reactivation Revenue**: I noticed New MRR appearing in late 2025 even though acquisition cohorts ended in 2024. This turned out to be churned customers coming back, which correctly counts as new revenue while still keeping their original cohort.

## “Any other information you find important to document”

### Assumptions:

•	**12-Month Contract Logic**: The model follows the 1-year subscription rule strictly. Since upgrades or cancellations can only happen at renewal, all revenue changes are recognized at the 12-month renewal point.
•	**Month Exclusion Rule**: Following the Ninox logic, MRR is counted for the first calendar month of a subscription, but the month in which the subscription ends is excluded.
•	**Dataset Limitation**: The source data ends with renewal orders in late 2025. Because there is no renewal data after that, I assumed any remaining MRR eventually becomes Lost MRR when it drops to zero. As a result, the End-of-Period MRR reaches €0.00 by December 2026, marking the end of the available data timeline.
•	**Currency Calculations**: All euro amounts were converted to NUMERIC types to avoid rounding errors during currency conversion and tax calculations.

### Insights:

**Disclaimer**: All the insights and recommendations for the insights are solely based on the data provided as part of the case study.

•	**Insight 1**: While Ninox shows healthy growth through 2024, there is a catastrophic spike in Lost MRR starting in late 2025 and continuing into 2026.
**Recommendation**: Conduct an urgent Churn analysis for the 2026 period. Since subscriptions are strict 1-year terms, this suggests a mass failure to renew. Investigate if a specific product update or a new competitor entered the market during this window.
•	**Insight 2**: The Pro Plan is the primary revenue driver. The Pro plan contributes nearly twice the revenue of Starter plan. 
**Recommendation**: Double down on the Starter to Pro upgrade path. Use the Starter plan as a low-friction acquisition tool, but implement automated in-app triggers to migrate users to Pro as their usage, feature requirement or team size grows.
•	**Insight 3**: Ninox revenue is highly concentrated in the USA, Canada, UK, and France, making the business vulnerable to economic shifts in those specific regions.
**Recommendation**: Diversify the geographic portfolio. Increasing marketing spend in regions like Spain and Germany, could provide a safer growth alternative to the saturated markets.
•	**Insight 4**: Customer stickiness is high during the initial term, but the business faces a significant drop in revenue retention at the 12- and 24-month marks.
**Recommendation**: Deploy a Renewal Protection campaign because you know exactly when the 12-month term ends, the Customer Success team should proactively engage high-value accounts couple of months before the term ends, to secure the renewal and identify expansion opportunities before the user churn.
•	**Insight 5**: Contraction MRR (-€626) is currently a minor issue compared to full Churn (-€10,471), meaning customers are more likely to leave entirely than to downgrade their license counts.
**Recommendation**: Implement a Down sell Save-Offer. If a customer attempts to churn, offer them a path to contract (Contraction) rather than losing the account entirely. "MRR saved is just as powerful as MRR gained".




