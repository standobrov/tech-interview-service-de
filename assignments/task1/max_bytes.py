events = [
    {"timestamp": 45, "bytes": 280},
    {"timestamp": 3, "bytes": 300},
    {"timestamp": 67, "bytes": 150},
    {"timestamp": 12, "bytes": 100},
    {"timestamp": 89, "bytes": 420},
    {"timestamp": 23, "bytes": 10},
    {"timestamp": 56, "bytes": 250},
    {"timestamp": 1, "bytes": 50},
    {"timestamp": 78, "bytes": 320},
    {"timestamp": 34, "bytes": 180},
    {"timestamp": 91, "bytes": 380},
    {"timestamp": 15, "bytes": 75},
    {"timestamp": 42, "bytes": 290},
    {"timestamp": 8, "bytes": 160},
    {"timestamp": 73, "bytes": 110},
    {"timestamp": 29, "bytes": 240},
    {"timestamp": 61, "bytes": 220},
    {"timestamp": 7, "bytes": 60},
    {"timestamp": 85, "bytes": 350},
    {"timestamp": 36, "bytes": 95},
    {"timestamp": 52, "bytes": 270},
    {"timestamp": 19, "bytes": 130},
    {"timestamp": 74, "bytes": 190},
    {"timestamp": 41, "bytes": 310},
    {"timestamp": 6, "bytes": 80},
    {"timestamp": 68, "bytes": 200},
    {"timestamp": 25, "bytes": 170},
    {"timestamp": 83, "bytes": 360},
    {"timestamp": 14, "bytes": 120},
    {"timestamp": 57, "bytes": 260},
    {"timestamp": 92, "bytes": 400},
    {"timestamp": 38, "bytes": 210},
    {"timestamp": 11, "bytes": 90},
    {"timestamp": 69, "bytes": 330},
    {"timestamp": 26, "bytes": 140},
    {"timestamp": 84, "bytes": 370},
    {"timestamp": 47, "bytes": 230},
    {"timestamp": 2, "bytes": 70},
    {"timestamp": 71, "bytes": 340},
    {"timestamp": 33, "bytes": 155},
    {"timestamp": 58, "bytes": 275},
    {"timestamp": 16, "bytes": 105},
    {"timestamp": 79, "bytes": 315},
    {"timestamp": 44, "bytes": 285},
    {"timestamp": 9, "bytes": 85},
    {"timestamp": 65, "bytes": 325},
    {"timestamp": 28, "bytes": 165},
    {"timestamp": 81, "bytes": 355},
    {"timestamp": 53, "bytes": 245},
    {"timestamp": 18, "bytes": 115},
]

from collections import deque

def max_bytes(events):
    # Sort events by timestamp
    events.sort(key=lambda x: x['timestamp'])

    window = deque()
    current_sum = 0
    max_sum = 0

    for event in events:
        t = event['timestamp']
        b = event['bytes']

        # Remove events outside the window [t-4, t]
        while window and window[0]['timestamp'] < t - 4:
            removed = window.popleft()
            current_sum -= removed['bytes']

        # Add current event
        window.append(event)
        current_sum += b

        # Update maximum
        max_sum = max(max_sum, current_sum)

    return max_sum


print(max_bytes(events))  # Output: 450


print(max_bytes(events))