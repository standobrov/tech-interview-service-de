from app import max_bytes

# Проверим тест с неотсортированными событиями
events = [
    {"timestamp": 5, "bytes": 100},
    {"timestamp": 1, "bytes": 200},
    {"timestamp": 3, "bytes": 150},
    {"timestamp": 2, "bytes": 50},
]

print("Исходные события:")
for event in events:
    print(f"timestamp={event['timestamp']}, bytes={event['bytes']}")

# Отсортируем вручную для понимания
sorted_events = sorted(events, key=lambda e: e["timestamp"])
print("\nОтсортированные события:")
for event in sorted_events:
    print(f"timestamp={event['timestamp']}, bytes={event['bytes']}")

print(f"\nРезультат max_bytes: {max_bytes(events)}")

# Проверим все возможные окна:
print("\nВозможные окна (длина <= 5 сек):")
print("Окно [1,2,3]: 200+50+150 = 400")
print("Окно [1,2,3,5]: 200+50+150+100 = 500 (разница между 1 и 5 = 4 < 5)")
print("Правильный ответ: 500")
