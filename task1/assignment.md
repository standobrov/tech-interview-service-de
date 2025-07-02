# Task 1: Data Cleaning and Processing

## Problem Statement
You have been given a dataset of trading records that contains various data quality issues. Your task is to clean and standardize this data, then enrich it with exchange information.

## Input Files
- `trades.csv` - Raw trading data with quality issues
- `exchange_mapping.csv` - Mapping of stock symbols to exchanges

## Your Task
Create a data processing pipeline that:
1. Cleans and standardizes the trading data
2. Maps each trade to its corresponding exchange
3. Outputs clean, analysis-ready data

## Data Quality Issues
You'll find various issues in the data that need to be addressed:
- Inconsistent date formats
- Price values with currency symbols and extra spaces
- Missing values in various fields
- Inconsistent text formatting (spacing, capitalization)
- Duplicate records


## Expected Deliverables
- Clean CSV file with standardized data
- Simple Python script using pandas


## Requirements
Your solution should handle these core issues:
- Clean date formats (convert to YYYY-MM-DD)
- Remove currency symbols from prices ($)
- Standardize trader names (proper case, trim spaces)
- Normalize stock symbols (uppercase, trim)
- Add exchange information from mapping file
- Remove exact duplicates

## Evaluation Criteria
- **Functionality**: Does your solution clean the main data issues?
- **Pandas Usage**: Do you use appropriate pandas methods?
- **Code Structure**: Is your code organized and readable?

**Focus on getting a working solution rather than perfect edge case handling.**

## Time Estimate
This task should take approximately 30 minutes to complete.

## Questions?
If you have any questions or need clarification, please ask!
