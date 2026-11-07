import requests
import pandas as pd
import os
import time
import csv
import json
import math
from datetime import datetime, timezone, date
from zoneinfo import ZoneInfo

BERLIN_TZ = ZoneInfo("Europe/Berlin")
BASE_URL = "https://v6.bvg.transport.rest"
BASE_DIR = "/Users/ryu/Desktop/study/0_Sose2026/Data Science in Python and R/team/data"
TARGETS_CSV = os.path.join(BASE_DIR, "targets.csv")
OUTPUT_CSV = os.path.join(BASE_DIR, f"radar_delays_{datetime.now().strftime('%Y%m%d')}.csv")
STATE_FILE = os.path.join(BASE_DIR, "tracking_state.json")

RADIUS_M = 150       # check within 150 meters
WINDOW_BEFORE = 5    # start radar scan 5 mins before the scheduled time
WINDOW_AFTER = 15    # wait until 15 mins after the scheduled time

def meters_to_lat_lon_delta(meters, lat):
    """
    Convert distance in meters to latitude/longitude differences.
    """
    lat_delta = meters / 111_320
    lon_delta = meters / (111_320 * math.cos(math.radians(lat)))
    return lat_delta, lon_delta

def fetch_radar(lat, lon):
    """
    Returns a list of vehicles within a radius of RADIUS_M from the stop coordinates.
    """
    lat_r, lon_r = meters_to_lat_lon_delta(RADIUS_M, lat)
    params = {
        "north": lat + lat_r,
        "south": lat - lat_r,
        "east":  lon + lon_r,
        "west":  lon - lon_r,
        "results": 64,
        "duration": 0,
        "frames": 1,
        "polylines": "false",
    }
    r = requests.get(f"{BASE_URL}/radar", params=params, timeout=10)
    r.raise_for_status()
    data = r.json()
    return data.get("movements", [])

def is_trip_in_movements(movements, trip_id):
    """
    Locate the corresponding trip in the radar response.
    """
    for m in movements:
        if trip_id and m.get("tripId") == trip_id:
            return True
    return False

def save_result(target, actual_time, delay_sec):
    """
    Save the results to a CSV file when a bus is detected by the radar.
    """
    row = {
        "collected_at": datetime.now().isoformat(),
        "trip_id":      target["trip_id"],
        "stop_id":      target["stop_id"],
        "stop_name":    target["stop_name"],
        "line":         target["line"],
        "direction":    target["direction"],
        "planned_when": target["planned_when"],
        "actual_when":  actual_time,
        "delay_sec":    delay_sec,
    }
    file_exists = os.path.exists(OUTPUT_CSV)
    with open(OUTPUT_CSV, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=row.keys())
        if not file_exists:
            writer.writeheader()
        writer.writerow(row)

if not os.path.exists(TARGETS_CSV):
    print("[radar] targets.csv not found, run collect.py first")
    exit()

targets = pd.read_csv(TARGETS_CSV, dtype={"trip_id": str, "stop_id": str}).to_dict(orient="records")

"""
Exclude buses that were already caught or missed in the previous run.
"""
if os.path.exists(STATE_FILE):
    with open(STATE_FILE) as f:
        state = json.load(f)
    if state.get("date") != str(date.today()):
        matched_keys = set()
        expired_keys = set()
    else:
        matched_keys = set(map(tuple, state.get("matched", [])))
        expired_keys = set(map(tuple, state.get("expired", [])))
else:
    matched_keys = set()
    expired_keys = set()

if os.path.exists(OUTPUT_CSV):
    try:
        recorded = pd.read_csv(OUTPUT_CSV, dtype={"trip_id": str, "stop_id": str})
        for _, row in recorded.iterrows():
            matched_keys.add((row["trip_id"], row["stop_id"]))
    except Exception:
        pass

valid_keys = {(str(t["trip_id"]), str(t["stop_id"])) for t in targets}
matched_keys &= valid_keys
expired_keys &= valid_keys

now = datetime.now(timezone.utc)

# Combine scans when different buses pass the same stop
active_by_stop: dict[str, list] = {}

for target in targets:
    key = (target["trip_id"], target["stop_id"])
    if key in matched_keys or key in expired_keys:
        continue

    planned = datetime.fromisoformat(target["planned_when"])
    diff_min = (planned - now).total_seconds() / 60

    if diff_min > WINDOW_BEFORE:
        continue 

    if diff_min < -WINDOW_AFTER:
        expired_keys.add(key)
        print(f"[radar] missed: {target['line']} @ {target['stop_name']} (planned {target['planned_when']})")
        continue

    active_by_stop.setdefault(target["stop_id"], []).append(target)

print(f"[radar] active stops this cycle: {len(active_by_stop)}")

for stop_id, stop_targets in active_by_stop.items():
    lat = stop_targets[0].get("stop_lat")
    lon = stop_targets[0].get("stop_lon")

    if pd.isna(lat) or pd.isna(lon):
        for t in stop_targets:
            expired_keys.add((t["trip_id"], t["stop_id"]))
        print(f"[radar] no coordinates for stop {stop_id}, skipping")
        continue

    try:
        movements = fetch_radar(lat, lon)
    except Exception as e:
        print(f"[radar] API error for stop {stop_id}: {e}")
        time.sleep(0.65)
        continue

    # DEBUG: remove after confirming radar field names
    if movements:
        sample = movements[0]
        if "tripId" not in sample and "trip" not in sample:
            print(f"[radar] WARNING: movement has neither tripId nor trip. Keys: {list(sample.keys())}")
    # END DEBUG

    for target in stop_targets:
        if is_trip_in_movements(movements, target["trip_id"]):
            planned = datetime.fromisoformat(target["planned_when"])
            delay_sec = int((now - planned).total_seconds()) # calculate delay
            actual_time = now.astimezone(BERLIN_TZ).isoformat()
            save_result(target, actual_time, delay_sec)
            matched_keys.add((target["trip_id"], target["stop_id"]))
            print(f"[radar] matched: {target['line']} @ {target['stop_name']} delay={delay_sec}s")

    time.sleep(0.65)

# Update state.json
valid_keys = {(str(t["trip_id"]), str(t["stop_id"])) for t in targets}
with open(STATE_FILE, "w") as f:
    json.dump({
        "date":    str(date.today()),
        "matched": [list(k) for k in matched_keys & valid_keys],
        "expired": [list(k) for k in expired_keys & valid_keys],
    }, f)

remaining = len(targets) - len(matched_keys) - len(expired_keys)
print(f"[radar] scan done | matched={len(matched_keys)} expired={len(expired_keys)} remaining={remaining}")
