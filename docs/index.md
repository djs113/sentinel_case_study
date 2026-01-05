# Sentinel: A Tactical Intelligence Platform for Urban Security

**Sentinel** is a mission-critical platform designed to enhance the operational efficiency and situational awareness of the **Kochi City Police** during night patrols. It provides a holistic solution combining real-time unit tracking, intelligent route optimization, and a high-freshness tactical map.

## The Core Operational Challenges

Modern policing faces two distinct data problems: the **Static Data Challenge** (keeping maps current) and the **Dynamic Data Challenge** (reacting to live events).

1.  **The Static Challenge:** Urban environments change daily. Standard GIS pipelines estimated a **21-day render time** for the regional dataset, meaning patrol units were operating on dangerously outdated maps.
2.  **The Dynamic Challenge:** A simple map is not enough. Officers need to see their teammates' live locations and receive optimized routes during high-stress situations like emergency pursuits.

## The Engineering Solution: A Three-Pillar Architecture

I architected Sentinel as a unified platform built on three core engines, each designed to solve one of these challenges.

### 1. The Tactical Map Engine (ETL)
This is the automated "map factory" that solves the static data problem.

*   **ETL Transformation:** Reduced map generation from 21 days to **10 minutes** through deep PostGIS kernel tuning.
*   **Automation:** 100% "Zero-Touch" hardware orchestration wakes the i9 compute node, runs the pipeline, and hibernates.
*   **Impact:** Police units receive a fresh, high-resolution tactical map every morning at 3:00 AM.

### 2. The Real-Time Telemetry Engine
This engine solves the live tracking problem using a high-throughput, event-driven architecture.

*   **High-Velocity Ingestion:** A FastAPI endpoint backed by **Redis Streams** ingests thousands of GPS pings per second with sub-15ms latency.
*   **Decoupled Persistence:** A Python background worker consumes the stream, processes state changes, and performs atomic `bulk_write` operations to MongoDB, ensuring zero data loss.
*   **Impact:** The command center has a live, sub-second view of all active patrol units on the map.

### 3. The Intelligent Routing Engine
This engine provides operational guidance, transforming raw locations into actionable intelligence.

*   **Proprietary TSP Solver:** Utilizes a custom **Lin-Kernighan-Helsgaun (LKH) heuristic** to calculate the most efficient patrol routes for a given set of hotspots.
*   **Dynamic Rerouting:** Includes endpoints to generate the fastest point-to-point emergency routes (A*) and to intelligently re-plan a patrol's entire shift after an interruption.
*   **Impact:** Optimizes patrol coverage, reduces fuel consumption, and provides critical navigational support during emergencies.

---

### Final Platform Performance
| Component | Key Metric |
| :--- | :--- |
| **Map Freshness** | 24 Hours (previously 21 days) |
| **API Ingestion Latency** | < 15ms |
| **Real-time Update Lag**| < 1 second |
| **System Cost**| Zero (Temporal Compute) |