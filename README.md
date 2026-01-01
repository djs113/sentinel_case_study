# Sentinel: A High-Performance Geospatial Platform (Case Study)

This repository contains the technical documentation for **Sentinel**, a mission-critical night patrolling platform architected for the Kochi City Police. The primary focus of this case study is the high-throughput **Geospatial ETL Engine** that powers the system's tactical map awareness.

**The full, interactive case study is hosted live via GitHub Pages:**

### ➡️ [View the Sentinel Technical Case Study](https://your-username.github.io/your-repo-name/)

---

## The Engineering Challenge

The core problem was transforming raw, city-scale OpenStreetMap data into optimized vector tiles for a mobile police application. Standard, out-of-the-box configurations for this task resulted in an estimated **21-day render time**, making daily updates impossible and hindering operational readiness.

## The Solution: A 10-Minute Map Factory

I engineered a custom, containerized pipeline that reduced the end-to-end execution time to **10 minutes**—a **3,000% increase in efficiency**.

This was achieved through a combination of database kernel tuning, custom Python orchestration, and hardware-level automation.

![Sentinel Architecture Diagram](https://your-link-to-diagram-image.png) 
*(Self-host your Mermaid diagram image or link to the architecture page)*

---

## Key Technical Achievements Documented

This case study provides a deep dive into the following architectural pillars:

*   **Performance Engineering:**
    *   How PostgreSQL's JIT compiler was identified as a bottleneck and disabled.
    *   The strategy for tuning `random_page_cost` to leverage NVMe SSD speeds for spatial indexing.
    *   Scaling `shared_buffers` to enable in-memory geometry calculations.

*   **Infrastructure & Orchestration:**
    *   The use of a **Python Orchestrator** with Docker-in-Docker (DinD) logic to manage complex, multi-stage container lifecycles.
    *   The implementation of a **Temporal Computing** pattern, using ACPI Wake Timers and WSL Interop to run the high-performance i9 node only when needed, reducing idle power draw to zero.

*   **Data Integrity & Deployment:**
    *   A "Clean Slate" database strategy using `CASCADE` drops to ensure pipeline runs are idempotent and self-healing.
    *   The use of **PMTiles** and **Cloudflare R2** for cost-efficient, high-speed delivery to mobile field units.

---

## Technology Stack

*   **Orchestration:** Python, Docker, Docker Compose
*   **Database:** PostgreSQL, PostGIS
*   **Real-time Layer:** FastAPI, Redis Streams, MongoDB
*   **Infrastructure:** Windows 11, WSL2, GitHub Actions (for deployment)
*   **Cloud:** Cloudflare R2, Cloudflare Tunnels

---

This repository contains the source for the MkDocs documentation site. To run it locally:
```bash
# Install dependencies
pip install mkdocs-material pymdown-extensions

# Run the live-reloading server
mkdocs serve
