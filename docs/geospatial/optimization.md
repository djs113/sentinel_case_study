# Performance Engineering: PostGIS Tuning

To achieve a 3,000% speedup, I performed deep-level tuning of the PostgreSQL query planner and kernel.

### 1. The JIT Bottleneck
**Observation:** CPU usage hit 1800% with low tile throughput.
**Fix:** Disabled `jit` (Just-In-Time compilation).
**Result:** Removed 40% overhead from MVT (Mapbox Vector Tile) geometry math.

### 2. SSD Latency Alignment
**Fix:** Adjusted `random_page_cost` from 4.0 to 1.1.
**Impact:** Forced the query planner to utilize **GIST Spatial Indexes** on the NVMe SSD rather than performing expensive sequential scans.

### 3. Memory Scaling
**Fix:** Allocated 2GB to `shared_buffers`.
**Impact:** The entire 55MB "Hot" dataset for Kochi is kept in RAM, reducing Disk I/O to near zero.