# Pandas Quick Reference for Technical Interview

This file contains useful pandas operations for the technical interview tasks.

## Basic Operations

```python
import pandas as pd
import numpy as np

# Reading CSV files
df = pd.read_csv('filename.csv')

# Basic info
df.head()
df.info()
df.describe()
df.shape

# Column operations
df.columns
df['column_name']
df.column_name

# Filtering
df[df['column'] > value]
df[df['column'].isin(['value1', 'value2'])]

# Grouping and aggregation
df.groupby('column').agg({'other_column': 'sum'})
df.groupby('column').size()

# Sorting
df.sort_values('column', ascending=False)

# Merging DataFrames
pd.merge(df1, df2, on='key_column', how='inner')

# Memory optimization
df.memory_usage(deep=True)
df['column'] = df['column'].astype('category')
```

## Useful for Exchange Rate Analysis (Task 1)

```python
# Convert timestamp
df['timestamp'] = pd.to_datetime(df['timestamp'])

# Calculate daily statistics
daily_stats = df.groupby(df['timestamp'].dt.date).agg({
    'price': ['mean', 'min', 'max', 'std']
})

# Rolling windows
df['rolling_mean'] = df['price'].rolling(window=100).mean()

# Time-based filtering
df[df['timestamp'].dt.hour == 9]  # 9 AM trades
```

## Memory Optimization Tips (Task 2)

```python
# Check memory usage
df.memory_usage(deep=True).sum()

# Optimize dtypes
df['int_column'] = pd.to_numeric(df['int_column'], downcast='integer')
df['float_column'] = pd.to_numeric(df['float_column'], downcast='float')

# Use categories for repeated strings
df['category_column'] = df['category_column'].astype('category')

# Chunk processing for large files
chunk_size = 10000
chunks = []
for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    # process chunk
    chunks.append(chunk)
result = pd.concat(chunks, ignore_index=True)
```
