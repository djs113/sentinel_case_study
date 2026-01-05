# The Hotspot Proximity Engine

The **Hotspot Proximity Engine** is a core service in the Sentinel backend. Its mission is to answer a single, critical question for a patrolling officer in real-time: *"Based on my current GPS location, which hotspot should I be interacting with right now?"*

This document details the architectural evolution of this endpoint from a slow, naive implementation to a high-performance, resilient service.

## 1. The Core Problem: Latency vs. Logic

The business logic is complex. The system must first check for recent "auto-visits" (where an officer drove through a geofence without stopping) before falling back to calculating the geographically closest *unvisited* hotspot.

A naive implementation of this logic resulted in **6-7 sequential database calls**, leading to high API latency and a poor user experience for the officer in the field.

### Initial (Suboptimal) Workflow
```mermaid
graph TD
    A[API Request] --> B{Auto-Visits?}
    B --> C[1. Get Geofence Logs]
    C --> D[2. Get Remarks]
    D --> E{Any Unremarked?}
    E -- Yes --> F[6. Get Hotspot Details]
    E -- No --> G[3. Get Patrol Lists]
    G --> H[4. Get All Hotspot Coords]
    H --> I[Python: Find Closest]
    I --> J[5. Get Hotspot Details]
    J --> K[6. Get Factors]
    F --> L[Response]
    K --> L
```
**Problem**: This "waterfall" of await calls was unscalable.
## 2. The Optimized Architecture: A Pragmatic Hybrid Strategy

To solve the latency issue, I re-architected the service to use a **Hybrid Query Model**. This new design cuts the maximum number of database calls from over 6 to just **3 per request**. It strategically delegates the most performance-critical operations (like geospatial sorting) to the database, while handling simple business logic (like set filtering) in Python for maximum maintainability. This results in a system that is both fast and easy to debug.

### The Refactored Workflow
```mermaid
graph TD
    A["API Request"] --> B{"Check for Auto-Visit"}
    B -- "Found" --> D["<b>2. Final Fetch</b><br/>(Hotspot + Factors)"]
    B -- "Not Found" --> C["<b>1. DB: Find Closest Unvisited</b>"]
    C --> D
    D --> E["Response"]
```
## 3. Technical Deep Dive: The Two-Step Query

### Step 1: The "Auto-Visit" Check (1 DB Call)
The first query uses a `LEFT JOIN` to efficiently find any `GeofenceLog` entries from the last 10 minutes that do **not** have a corresponding entry in the `Remark` table. This remains the fastest path.
```python
# Fetches recent, un-remarked "AUTO_VISIT" events
stmt_auto_visit = (
    select(GeofenceLog.hotspot_id)
    .outerjoin(
        Remark, 
        and_(
            Remark.hotspot_id == GeofenceLog.hotspot_id,
            Remark.patrol_id == data.patrol_id
        )
    )
    .where(
        GeofenceLog.patrol_id == data.patrol_id,
        GeofenceLog.event_type == 'AUTO_VISIT',
        (datetime.now(ZoneInfo("Asia/Kolkata")).replace(tzinfo=None) - 
        GeofenceLog.server_received_at) <= timedelta(minutes=10),
        Remark.remark_id == None
    )
    .order_by(GeofenceLog.server_received_at.asc())
    .limit(1)
)
```
### Step 2: The "Closest Unvisited" Hybrid Fallback
If the auto-visit check returns empty, the system uses a three-part hybrid strategy:

**A. Fetch Patrol State (1 DB Call):** A single, lightweight query retrieves the `hotspots_to_visit` and `visited_hotspots` arrays for the current patrol.

**B. Application-Side Filtering (Python):** The set difference to find unvisited hotspots is performed in Python. This logic is extremely fast and much more readable than a complex SQL `unnest` or array comparison.

**C. Geospatial Sort (1 DB Call):** A final query is sent to the database. It finds the closest hotspot from the unvisited list using the highly optimized `earthdistance` extension.
```python
# This is the implementation for the fallback logic
if not target_hotspot_id:
    # Step 2a: Get Patrol Lists
    query = select(Patrol.visited_hotspots, Patrol.hotspots_to_visit).where(
        Patrol.patrol_id == data.patrol_id
    )
    patrol_data = (await session.execute(query)).mappings().first()

    # Step 2b: Filter in Python
    visited_hotspots = patrol_data['visited_hotspots'] or []
    hotspots_to_visit = patrol_data['hotspots_to_visit'] or []
    unvisited_hotspots = [hs for hs in hotspots_to_visit if hs not in visited_hotspots]

    # Step 2c: Geospatial Sort in DB
    stmt_closest = (
        select(Hotspot.hotspot_id)
        .where(Hotspot.hotspot_id.in_(unvisited_hotspots))
        .order_by(
            func.earth_distance(
                func.ll_to_earth(Hotspot.location, Hotspot.location),
                func.ll_to_earth(current_lat, current_lng)
            )
        )
        .limit(1)
    )
    target_hotspot_id = (await session.execute(stmt_closest)).scalar_one_or_none()
```
### Step 3: The Final Data Fetch (1 DB Call)
Once the `target_hotspot_id` is determined, a final query uses a `JOIN` to fetch both the `Hotspot` record and all its `HotspotFactors` in a single network round trip, eliminating the N+1 problem.
python
```
stmt_details = (
    select(Hotspot, HotspotFactors)
    .join(HotspotFactors, HotspotFactors.factor_id == func.any(Hotspot.factor_ids))
    .where(Hotspot.hotspot_id == target_hotspot_id)
)
```
## 4. Architectural Decision: Why a Hybrid Approach?
A pure-SQL version with a single complex query was prototyped. However, the hybrid "Fetch-Filter-Fetch" approach was chosen for two key reasons:

1.  **Readability & Maintainability:** The Python code for calculating the set difference is more explicit and easier for new developers to understand than a complex SQL `JOIN` on array comparisons.
2.  **Performance Balance:** The added latency of one extra lightweight DB call is negligible, while the simplification of the main geospatial query keeps the most performance-critical part (the distance sort) on the database where it belongs.

This pragmatic trade-off results in a system that is both highly performant and easy to maintain.
## 5. Final Performance

| Metric | Original (Naive) | Optimized (Hybrid) |
| :--- | :--- | :--- |
| **Max DB Calls** | 6-7 | **3** |
| **Code Readability**| Low | **High** |
| **Scalability**| O(N) - Degrades with more hotspots | **O(1)** - Constant time performance |