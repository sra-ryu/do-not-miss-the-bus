import requests
import pandas as pd
import os
from datetime import datetime
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import time

BASE_URL = "https://v6.bvg.transport.rest"

def get_station_id(search_term):
    url = f"{BASE_URL}/locations"
    params = {
        "query": search_term,
        "results": 1
    }
    
    response = requests.get(url, params=params)
    
    if response.status_code != 200:
        print(f"API Error: HTTP {response.status_code}")
        return None
    
    data = response.json()
    if not data:
        print("No results found.")
        return None

    station = data[0]
    print(f"Found: {station['name']} -> ID: {station['id']}")
    return station['id']

stops = [
    "S Mehrower Allee",
    "Glambecker Ring",
    "Landsberger Allee/Blumberger D.",
    "Cecilienstr./Blumberger Damm",
    "U Elsterwerdaer Platz",
    "Chemnitzer Str./Jägerstr.",
    "S Köpenick",
    "Alte Erpe",
    "S.-Allende-Str./Wendenschloßstr.",
    "Erwin-Bock-Str."
]

stop_ids = []
for stop_name in stops:
    stop_id = get_station_id(stop_name)
    if stop_id:
        stop_ids.append(stop_id)
        
print(stop_ids)