## Project Overview

Analyze SaaS revenue, profitability, and customer usage to evaluate whether growth is sustainable or driven by discounting. The project links sales data with usage behavior to identify customer risk, pricing issues, and product-level value leakage.

## Business Problem

Revenue alone does not indicate customer health in SaaS. High sales can mask:
Low product adoption
Excessive discounting
Margin erosio
Early churn risk

This project addresses that gap by combining financial metrics with usage signals.

## Key Questions

Why can revenue growth be misleading in SaaS?
Which customers appear profitable but are actually risky?
How does discounting impact profit and engagement?
Which products generate revenue but destroy margin?

## Data

Sales & Revenue Data: Orders, revenue, profit, discounts
Customer Usage Data: Synthetic dataset simulating realistic SaaS usage behavior
Product, Customer, Region Dimensions
Usage data is synthetic due to privacy constraints.

## Tools Used

SQL – Data extraction and joins
Pandas – Cleaning, transformation, and modeling
Excel – Validation and exploratory checks
Power BI – Interactive dashboard and reporting

## Metrics

Revenue & profit trends (MoM / YoY)
Discount impact on margin
Customer revenue vs usage activity
Product-level profitability and engagement
Segment and regional concentration

## Key Findings

Discounts above 20% consistently produced negative margins
High-revenue customers were not always highly engaged
Certain products showed strong adoption but negative profitability
Revenue was concentrated in SMB customers and select regions

## Output

Interactive Power BI dashboard for monitoring:
Growth quality
Customer risk
Discount effectiveness
Product performance
