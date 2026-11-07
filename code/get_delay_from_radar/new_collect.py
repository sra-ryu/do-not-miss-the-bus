import requests
import pandas as pd
import os
import time
from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

BASE_URL = "https://v6.bvg.transport.rest"
BERLIN_TZ = ZoneInfo("Europe/Berlin")

BUS_LINES = {
    "140": ['900068202', '900068253', '900068102', '900017101', '900016101',
            '900012152', '900013103', '900013151', '900013102', '900014153'],
    "120": ['900096314', '900096193', '900096101', '900096454', '900085104',
            '900085152', '900011151', '900009103', '900009104', '900008107'],
    "194": ['900075103', '900190506', '900190001', '900120003', '900160001',
            '900160534', '900161512', '900181002', '900171002', '900171539'],
    "M11": ['900066103', '900066101', '900064301', '900064357', '900072101',
            '900072103', '900080651', '900082202', '900083181', '900194526'],
    "M29": ['900048153', '900040101', '900023302', '900023351', '900056101',
            '900005105', '900012101', '900012104', '900014101', '900015103'],
    "M41": ['900077156', '900077155', '900077106', '900076153', '900078105',
            '900016252', '900016103', '900012103', '900100020', '900100022'],
    "M45": ['900027252', '900029302', '900031101', '900025202', '900025252',
            '900020234', '900022103', '900022202', '900023101', '900023172'],
    "M48": ['900049241', '900050251', '900066105', '900062202', '900061101',
            '900054105', '900054109', '900056104', '900005205', '900100022'],
    "X54": ['900130014', '900141002', '900140002', '900140018', '900150022',
            '900152001', '900152502', '900170002', '900170001', '900175554'],
    "X69": ['900170003', '900170510', '900170013', '900171010', '900171006',
            '900175008', '900180001', '900180536', '900180020', '900180527']
}

BASE_DIR = "/Users/ryu/Desktop/study/0_Sose2026/Data Science in Python and R/team/data"
TARGETS_CSV = os.path.join(BASE_DIR, "targets.csv")
TARGETS_DATE_FILE = os.path.join(BASE_DIR, "targets_date.txt")


# Get next 90 mins departures(trip_id, stop_lat/lon, bus-schedule)
def get_departures(stop_id, line_name):
    url = f"{BASE_URL}/stops/{stop_id}/departures"
    params = {
        "duration": 70, # next 70 mins
        "bus": "true", # only bus
        "suburban": "false",
        "subway": "false",
        "tram": "false",
        "ferry": "false",
        "express": "false",
        "regional": "false",
    }

    # If it fails, try 3 times
    for attempt in range(3):
        try:
            r = requests.get(url, params=params, timeout=10)
            r.raise_for_status()
            departures = r.json().get("departures", [])
            break
        except Exception as e:
            if attempt < 2:
                time.sleep(5) # retry after 5 seconds
            else:
                print(f"[collect] skipping stop {stop_id}: {e}")
                return [] # after 3 tries, skip this process

    results = []
    for d in departures:
        if d.get("line", {}).get("name") != line_name:
            continue
        if not d.get("tripId") or not d.get("plannedWhen"):
            continue
        stop = d.get("stop", {})
        loc = stop.get("location", {})
        results.append({
            "trip_id": d["tripId"],
            "stop_id": stop_id,
            "stop_name": stop.get("name", ""),
            "stop_lat": loc.get("latitude"),
            "stop_lon": loc.get("longitude"),
            "line": line_name,
            "direction": d.get("direction", ""),
            "planned_when": d["plannedWhen"],
        })
    return results

def collect_tracking_targets(bus_lines):
    seen = set()
    targets = []
    
    for line_name, stop_ids in bus_lines.items():
        for stop_id in stop_ids:
            for t in get_departures(stop_id, line_name):
                key = (t["trip_id"], t["stop_id"])
                if key not in seen:
                    seen.add(key)
                    targets.append(t)
            time.sleep(0.65)
    return targets

os.makedirs(BASE_DIR, exist_ok=True)
today = str(date.today())

# Reset targets.csv when the date changes
if os.path.exists(TARGETS_DATE_FILE):
    with open(TARGETS_DATE_FILE) as f:
        saved_date = f.read().strip()
    if saved_date != today:
        if os.path.exists(TARGETS_CSV):
            os.remove(TARGETS_CSV)
        print(f"[collect] new day ({today}), targets.csv reset")

with open(TARGETS_DATE_FILE, "w") as f:
    f.write(today)

existing_keys = set()
if os.path.exists(TARGETS_CSV):
    try:
        existing = pd.read_csv(TARGETS_CSV, dtype={"trip_id": str, "stop_id": str})
        now = datetime.now(timezone.utc)
        planned_dt = pd.to_datetime(existing["planned_when"], utc=True)
        existing = existing[planned_dt > now - pd.Timedelta(minutes=15)]
        existing.to_csv(TARGETS_CSV, index=False)
        existing_keys = set(zip(existing["trip_id"], existing["stop_id"]))
    except Exception as e:
        print(f"[collect] warning: {e}")

# Collect new targets and delete duplications
new_targets = collect_tracking_targets(BUS_LINES)
targets_to_add = [
    t for t in new_targets
    if (str(t["trip_id"]), str(t["stop_id"])) not in existing_keys
]

if targets_to_add:
    df_new = pd.DataFrame(targets_to_add)
    write_header = not os.path.exists(TARGETS_CSV)
    df_new.to_csv(TARGETS_CSV, mode="a", header=write_header, index=False)
    skipped = len(new_targets) - len(targets_to_add)
    print(f"[collect] appended {len(targets_to_add)} new targets (skipped {skipped} duplicates)")
else:
    print(f"[collect] no new targets (all {len(new_targets)} were duplicates)")
