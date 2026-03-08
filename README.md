NINOX CASE STUDY 

Data modeling approach and architecture decisions:
I implemented an ELT (Extract, Load, Transform) architecture using a layered approach within dbt to transform raw transactional data into actionable metrics.
The raw dataset is structured as a Snowflake Schema. The central Fact Table (Orders) contains the financial events but lacks direct user keys, requiring a chain of joins through the Subscriptions Dimension to reach the Users Dimension (Orders → Subscriptions → Users).
Transformation Layers in dbt:
Staging Layer (stg_): This layer acts as a mirror of the raw CSV files. This layer handles data cleanup, removing duplicates, casting timestamp strings to proper DATE types for calculation, and parsing JSON metadata.


Intermediate Layer (int_): 
Scaffolding (Data Explosion): Each order covers a 12-month term but is stored as a single row. To analyze revenue month by month, I “expanded” each order by combining it with a list of months (0–11), creating a continuous monthly timeline for every transaction.
MRR Movement Logic: Using the LAG() function, I compared monthly recurring revenue (MRR) for each customer month over month. This lets me categorize MRRinto types like New, Expansion, Contraction, Lost, or Start of Period.
Cohort Retention Logic: To track customer stickiness, I identified the Start Month for every user using (MIN(reporting_month)). I then calculated a standardised Age Index (Month 0 to 35). This logic links multiple years of renewal orders back to the original acquisition date, giving a true picture of long term customer value.
Marts Layer (fct_): This layer is the final, reporting-ready stage of the data pipeline, where detailed logic is turned into structured tables ready for analysis. It includes three tables.

fct_mrr_movements_monthly: Summarizes revenue changes per month, showing totals for all movement types: Start of Period, New, Expansion, Contraction, Lost, and End of Period.
fct_mrr_movements_reporting: Builds on the monthly summary but keeps Country and Plan details. This lets me explore revenue trends interactively by country or plan, supporting charts like waterfalls.
fct_mrr_cohorts: Tracks customer cohorts from their first month over a 36 month time, showing retained revenue and retention percentage for cohort analysis and triangular heatmaps.


Macros: To keep the calculations consistent and the code clean I moved the key formulas into three dbt macros:
calculate_net_revenue: Converts gross revenue to net by removing tax and applying exchange rates so all revenue is standardised in EUR.
calculate_mrr: Calculates monthly recurring revenue by dividing net revenue by the fixed 12-month subscription term.
to_start_of_month: Converts any date to the first day of its month so cohort analysis and monthly reporting stay accurate.
Visualization : To clearly show MRR trends and cohort retention, I built an interactive dashboard in Power BI.
MRR Dashboard :
Monthly Growth Trend (Column Chart): This chart shows the End of Period MRR for each month and year, giving a quick view of how the company’s revenue is growing over the 36month period.
MRR Movements (Waterfall Chart): This chart explains how MRR changes from the Start of Period to the End of Period by breaking it into New, Expansion, Contraction, and Lost revenue. It helps quickly see whether growth is stronger than revenue losses.
MRR Summary Cards: Simple cards highlight key metrics such as New, Expansion, Lost, and Contraction MRR, allowing stakeholders to quickly understand the main revenue drivers.
Interactive Filters: I added slicers for Country and Plan Name so stakeholders can explore trends by Country or plan tier and identify high value segments or potential churn risks.

MRR Cohort Retention dashboard:

Retention Heatmap (Matrix Chart): I used a heatmap to track customer cohorts based on the month they were acquired. This makes it easy to analyze how a specific group of customers behaves over time (horizontally) and also compare different cohorts at the same stage in their lifecycle, such as Month 12 renewals (vertically).
Interactive Filters: I added a year slicer so stakeholders can quickly compare cohort performance across different years.
—---------------------------------------------------------------------------------------------------------------------------------------------------------------

Tools and Technologies:

BigQuery: I have chosen BigQuery as my data warehouse because of its fast query performance and seamless integration with popular data visualization and modeling tools like powerbi and dbt. It’s also simple to use, scales well as data grows.
dbt (Data Build Tool): To clean and model the raw CSV files, I used dbt because it makes it easy to create different models for different purposes. In my case study, I created a staging layer for cleaning the data, an intermediate layer to perform calculations and join tables, and a mart layer to generate the final output for visualization. Beyond this, dbt allows me to maintain data quality by adding multiple tests in YML files, ensuring that the data remains reliable and consistent.
Additionally, dbt integrates well with version control systems like Git, which helps track changes and maintain a clear history of code updates. By organizing the project into layers and using tests with version control, I found it much easier to manage and maintain the code over time.
GitHub: I used GitHub for code versioning, which helped me keep track of all changes and manage different versions of my project. It also served as the primary platform for submitting my work, ensuring everything is organized and easy to access.
Power BI: Power BI: To visualize the MRR movements and MRR cohort retention, I used Power BI because it allows me to create interactive and actionable dashboards, which are essential for effective data storytelling. Power BI also offers a wide range of visualization options, easy integration with data sources, and the ability to share insights seamlessly with stakeholders, making it a powerful tool for turning data into decisions.
—---------------------------------------------------------------------------------------------------------------------------------------------------------------



Data Insights and Handling Strategies:

Duplicate Orders: Some rows in orders.csv had the same order_id repeated with identical details. I fixed this in the staging layer by grouping them together so revenue wouldn’t be counted multiple times.
Missing Subscription Dates: A few records were missing start_date or end_date. I kept them in the staging layer so dbt tests could flag them, but excluded them from the monthly expansion since a full 12-month timeline couldn’t be created.
Licence Anomaly: One customer had a subscription with 0 licenses but still paid $220.80. I treated the payment as valid revenue because the financial transaction is the most reliable source of truth.
Null Tax Values: Tax fields for some records in the JSON metadata were null. Instead of guessing a value, I replaced nulls with 0% to avoid incorrectly reducing reported revenue.
Reactivation Revenue: I noticed New MRR appearing in late 2025 even though acquisition cohorts ended in2024. This turned out to be churned customers coming back, which correctly counts as new revenue while still keeping their original cohort.

-----------------------------------------------------------------------------------------------------------------------------------------------------

Assumptions:

12-Month Contract Logic: The model follows the 1-year subscription rule strictly. Since upgrades or cancellations can only happen at renewal, all revenue changes are recognized at the 12-month renewal point.
Month Exclusion Rule: Following the Ninox logic, MRR is counted for the first calendar month of a subscription, but the month in which the subscription ends is excluded.
Dataset Limitation: The source data ends with renewal orders in late 2025. Because there is no renewal data after that, I assumed any remaining MRR eventually becomes Lost MRR when it drops to zero. As a result, the End-of-Period MRR reaches €0.00 by December 2026, marking the end of the available data timeline.
Currency Calculations : All euro amounts were converted to NUMERIC types to avoid rounding errors during currency conversion and tax calculations.

Insights:

Top Markets Drive Revenue:  USA, Canada, France, and UK generate the majority of MRR, making them critical for growth. 
Suggestion :Focus on protecting and expanding these markets.


Pro Plan is Key Revenue Driver : The Pro plan contributes nearly twice the revenue of Starter. 
Suggestion :Encouraging Starter to Pro upgrades can significantly boost MRR.


Weaker Performance in Some Markets : Germany and Spain show low expansion and higher churn, indicating weaker product-market fit. 
Suggestion :Targeted retention and localization strategies are needed.

Customer Revenue Retention Drop : Retention remains strong (~100%) during the first 10–11 months but declines to ~84% after 12 months and ~74% after 24 months, indicating churn aligns with yearly renewals rather than early lifecycle.
Suggestion : Implement proactive retention strategies in months 9–12, including customer success check ins, upsell campaigns and early renewal discounts to maintain retention above 90%
