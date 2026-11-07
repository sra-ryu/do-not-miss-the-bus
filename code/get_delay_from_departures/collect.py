import requests
import pandas as pd
import os
from datetime import datetime
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import time

BASE_URL = "https://v6.bvg.transport.rest"

def get_bus_delay(stop_id, line_name, output_csv="bus_delays.csv"):
    url = f"{BASE_URL}/stops/{stop_id}/departures"
    params = {"duration": 12}

    departures = []
    
    # retry 3 times if request fails
    for attempt in range(3):
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()

            data = response.json()
            departures = data.get("departures", [])
            break

        except Exception as e:
            print(f"Attempt {attempt + 1}: {e}")

            if attempt < 2:
                time.sleep(5)

    else:
        print(f"Skipping stop {stop_id}")
        return None

    filtered = [
        d for d in departures
        if d.get("line", {}).get("name") == line_name
    ]

    if not filtered:
        print(f"No departures found for {line_name} at stop {stop_id}")
        return None

    rows = [{
        "collected_at": datetime.now().isoformat(),
        "trip_id": d.get("tripId", ""),
        "stop_id": stop_id,
        "stop_name": d.get("stop", {}).get("name", ""),
        "line": line_name,
        "direction": d.get("direction", ""),
        "planned_when": d.get("plannedWhen", ""),
        "actual_when": d.get("when", ""),
        "delay_sec": d.get("delay", 0) or 0,
    } for d in filtered]

    df = pd.DataFrame(rows)

    if os.path.exists(output_csv):
        df.to_csv(output_csv, mode="a", header=False, index=False)
    else:
        df.to_csv(output_csv, index=False)

    # print(df[["line", "direction", "planned_when", "delay_sec"]])
    # print(f"Saved to {output_csv}")


""" BUS LINES """
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

BASE_DIR = "" # set path of directory
os.makedirs(BASE_DIR, exist_ok=True)

output = os.path.join(BASE_DIR, f"bus_delays_{datetime.now().strftime('%Y%m%d')}.csv")

# print for test
# for line_name, stop_ids in BUS_LINES.items():
#     print(f"\n=== Line {line_name} ===")
#     for stop_id in stop_ids:
#         print(f"--- {stop_id} ---")
#         get_bus_delay(stop_id, line_name, output_csv=output)
        
for line_name, stop_ids in BUS_LINES.items():
    for stop_id in stop_ids:
        get_bus_delay(stop_id, line_name, output_csv=output)