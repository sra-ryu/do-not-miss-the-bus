# Don't Miss the Bus
 
Course project for **Data Science in Python and R** (TU Berlin, Summer Semester 2026), done in a team of four.
 
**Research question:** How do time of day and location predict the arrival time required to achieve a 95% probability of catching selected buses in Berlin?
 
This repository contains **my part** of the project: collecting the bus data (Python), cleaning it, and analysing and visualising it (R).


## Data collection (Python)
 
Data comes from [v6.bvg.transport.rest](https://v6.bvg.transport.rest), a community REST wrapper around the BVG (Berlin public transport) backend. I tracked 10 bus lines (120, 140, 194, M11, M29, M41, M45, M48, X54, X69) with 10 stops each, collected every day.
 
- `code/get_delay_from_departures/` collects the departures of each stop and saves the planned time, the estimated actual time and the delay in seconds. `get_id.py` looks up stop IDs by name.
- `code/get_delay_from_radar/` is an attempt to measure delays in real time. The API's delay is only an estimate, so this script looks for the tracked bus within 150 m of the stop (from 5 minutes before to 15 minutes after its scheduled time) and compares the time it shows up with the timetable.

The radar approach was not reliable enough. Buses sometimes pass through the small radius too quickly to be detected, and a larger radius stops being "real time", because in traffic a few hundred metres can take a long time.
 
During the collection period, a record-breaking heat wave hit Europe and the server became unstable, so for 2-3 days no data could be collected properly. The departures-based collection recovered faster than the radar approach. For stability, the final dataset therefore mostly uses the estimated delays from the departures API.

## Scheduling
 
The collection ran automatically on my Mac with `cron`, every day between 8:00 and 19:00:

```
*/10 8-18 * * * python3 <path to collect.py> >> collect_log.txt 2>&1
0    8-18 * * * python3 <path to new_collect.py> >> collect_log.txt 2>&1
*    8-18 * * * python3 <get_targets.py>> >> radar_log.txt 2>&1
```

- `collect.py` runs every 10 minutes and saves the estimated delays.
- `new_collect.py` runs every hour and builds the list of upcoming trips for the radar to track.
- `get_targets.py` runs every minute and scans the radar for those trips.


## Data processing (R)
 
Run these from the project root, in this order:
 
1. `merge_data.R` combines the daily CSV files and removes duplicates (keeps the latest record per trip and stop).
2. `add_location_columns.R` adds the district of each stop and whether the trip goes toward or away from the city centre. Output: `data/final_data.csv`.
3. `split_week.R` splits the data into weekdays and weekends.

Delay is `delay_sec`: positive means late, negative means early.

## Analysis and visualisation (R)
 
- `graph_for_all_lines.R` and `graph_for_each_line.R` show the average delay per line and the delay quartiles per hour.
- `city_vs_outer_buffer.R` compares trips toward and away from the centre. The buffer needed to catch the bus 95% of the time is the absolute value of the 5th percentile of the delay (early arrivals are the risk).
- `districts_buffer.R` shows the share of early arrivals per district and highlights the top 3.
- `rush_hour_buffer.R` calculates the buffers for the morning (8-9) and afternoon (15-17) rush hours.

The resulting graphs are in `graphs/`.

## Project structure
 
- `code/` Python scripts for data collection
- `r_scripts/` R scripts for processing and visualisation
- `data/` collected and processed CSV files
- `graphs/` graphs produced by the R scripts

---
 
(Korean ver.)

# Don't Miss the Bus

**Data Science in Python and R** 수업(TU Berlin, 2026 여름학기)에서 4명이 함께 한 팀 프로젝트입니다.

**연구 질문:** 베를린에서 특정 버스를 탈 확률을 95%로 맞추기 위해 필요한 도착 시간은, 시간대와 위치에 따라 어떻게 예측될 수 있을까?

이 저장소에는 팀 프로젝트에서 **제가 맡은 부분**만 있습니다. 버스 데이터 수집(Python), 정리, 분석과 시각화(R)입니다.

## 데이터 수집 (Python)

데이터는 BVG(베를린 대중교통 회사)의 벡엔드를 감싼 커뮤니티 REST API인 [v6.bvg.transport.rest](https://v6.bvg.transport.rest)에서 가져왔습니다. 베를린 10개 버스 노선 버스 10개 노선(120, 140, 194, M11, M29, M41, M45, M48, X54, X69)을 노선당 정류장 10개씩, 매일 수집했습니다.

- `code/get_delay_from_departures/`는 각 정류장의 출발 정보를 받아 예정 시간, 예상 실제 시간, 지연(초)을 저장합니다. `get_id.py`는 정류장 이름으로 ID를 찾습니다.
- `code/get_delay_from_radar/`는 실시간 지연을 측정해 보려는 시도입니다. API가 주는 지연은 예측값이라서, 정류장 150m 이내(예정 시간 5분 전부터 15분 후까지)에 추적 중인 버스가 들어오는 시각을 확인해 시간표와 비교했습니다.


radar 방식은 충분히 안정적이지 않았습니다. 버스가 좁은 반경을 너무 빨리 지나가서 놓치기도 했고, 반경을 넓히면 더 이상 실시간이 아니었습니다. 막히는 시간대에는 몇백 미터를 가는 데도 오래 걸리기 때문입니다. 그래서 최종 데이터는 안정성을 위해 departures API의 추정 지연값을 주로 사용했습니다.

수집 기간 중 유럽에 기록적인 폭염이 닥친 이후 서버가 불안정해져, 2~3일간은 데이터를 제대로 수집하지 못했습니다. 이후에도 departures 방식이 radar 방식보다 더 빨리 안정화되었습니다. 그래서 최종 데이터는 안정성을 위해 departures API의 추정 지연값을 사용했습니다.

## 자동 실행

수집은 맥에서 `cron`으로 매일 8시부터 19시 사이에 자동으로 실행했습니다.

```
*/10 8-18 * * * python3 <path to collect.py> >> collect_log.txt 2>&1
0    8-18 * * * python3 <path to new_collect.py> >> collect_log.txt 2>&1
*    8-18 * * * python3 <get_targets.py>> >> radar_log.txt 2>&1
```

- `collect.py`: 10분마다 실행해 추정 지연값을 저장합니다.
- `new_collect.py`: 1시간마다 실행해 radar가 추적할 앞으로의 운행 목록을 만듭니다.
- `get_targets.py`: 1분마다 실행해 그 목록의 버스가 radar에 잡히는지 확인합니다.

## 데이터 처리 (R)

프로젝트 루트에서 아래 순서로 실행합니다.
 
1. `merge_data.R`: 일별 CSV 파일을 합치고 중복(같은 trip과 정류장은 가장 최근 기록만)을 제거합니다.
2. `add_location_columns.R`: 정류장이 속한 구(district)와 도심 방향/외곽 방향 여부를 추가합니다. 결과는 `data/final_data.csv`입니다.
3. `split_week.R`: 평일과 주말 데이터로 나눕니다.

지연은 `delay_sec`이며, 양수는 늦은 도착, 음수는 일찍 도착입니다.

## 분석과 시각화 (R)

- `graph_for_all_lines.R`, `graph_for_each_line.R`: 노선별 평균 지연과 시간대별 지연 사분위수 그래프를 그립니다.
- `city_vs_outer_buffer.R`: 도심 방향과 외곽 방향을 비교합니다. 버스를 95% 확률로 타기 위한 버퍼는 지연의 5번째 백분위수의 절댓값입니다(일찍 도착하는 것이 놓칠 위험이기 때문입니다).
- `districts_buffer.R`: 구별로 일찍 도착하는 비율을 보여주고 상위 3곳을 표시합니다.
- `rush_hour_buffer.R`: 아침(8-9시)과 오후(15-17시) 러시아워의 버퍼를 계산합니다.

결과 그래프는 `graphs/`에 있습니다.

## 프로젝트 구조
 
- `code/` 데이터 수집용 Python 스크립트
- `r_scripts/` 데이터 처리와 시각화용 R 스크립트
- `data/` 수집한 데이터와 처리된 CSV 파일
- `graphs/` R 스크립트로 만든 그래프
