Task: Maximum Aggregated Data Volume in a Sliding Time Window

You are given a list of events, where each event is represented as a dictionary with two keys:
- 'timestamp': an integer representing the time in seconds when the event occurred
- 'bytes': an integer representing the size of data (in bytes) transferred at that timestamp

Your goal is to implement a function `max_bytes(events)`
that returns the maximum total number of bytes transferred within any 5-second sliding window.

The window is defined as a half-open interval [t, t + 5),
meaning it includes events that occurred at time t but excludes events at time t + 5.

Notes:
- Events may not be sorted by timestamp.
- Timestamps are positive integers.
- There may be multiple events with the same timestamp.

Example:
events = [
    {"timestamp": 1, "bytes": 100},
    {"timestamp": 2, "bytes": 50},
    {"timestamp": 3, "bytes": 300},
    {"timestamp": 6, "bytes": 10},
    {"timestamp": 7, "bytes": 30},
]

max_bytes(events) should return 450, since the window [1, 6) contains the first three events,
with a total of 100 + 50 + 300 = 450 bytes.