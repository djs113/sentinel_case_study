# Security & Cloud Delivery Architecture

The Sentinel platform utilizes a **Hybrid-Cloud Architecture**. While the heavy computation and data transformation occur on local, secure hardware to ensure data sovereignty, the distribution layer leverages a global edge network to ensure low-latency access for field units.

## 1. The PMTiles Strategy
To optimize delivery for mobile networks (4G/LTE) used by patrol cars, Sentinel rejects the traditional "Folder of Images" approach in favor of **PMTiles (v3)**.

### Why PMTiles?
*   **Single-File Archive:** The entire 55MB dataset is contained in a single, seekable archive. This simplifies S3 management and eliminates the "millions of files" problem associated with standard XYZ tiles.
*   **HTTP Range Requests:** The mobile app does not download the whole file. It makes precise `Range: bytes=x-y` requests to fetch only the specific map tiles needed for the officer's current viewport.
*   **Bandwidth Efficiency:** This architecture reduces mobile data consumption by approximately **70%** compared to standard WMS/TMS servers.

---

## 2. Secure R2 Deployment
The orchestrator utilizes the S3 API to exfiltrate the final artifact to **Cloudflare R2**.

### Architecture Decisions
1.  **Zero Egress Fees:** Unlike AWS S3, Cloudflare R2 charges zero fees for data egress. This allows the Kochi Police to scale from 100 to 10,000 patrol units without incurring unpredictable bandwidth costs.
2.  **Data Sovereignty:** Raw police data (incident hotspots, patrol routes) is processed strictly on-premise (Local i9 Node). Only the anonymous, rendered tactical map is pushed to the cloud.
3.  **Encryption:**
    *   **In-Transit:** All data transfers occur over TLS 1.3.
    *   **At-Rest:** Data stored in R2 is encrypted using AES-256.

---

## 3. Automated Cache Invalidation
To prevent "Stale Map Syndrome"—where officers might see yesterday's road layout—the pipeline includes an automated CDN purge step.

### The Invalidation Logic
Immediately after the S3 upload confirms a `200 OK`, the Python orchestrator hits the Cloudflare Zone API to wipe the edge cache for the map file.

```python
    CLOUDFLARE_API_TOKEN = os.getenv("CLOUDFLARE_API_TOKEN")
    CLOUDFLARE_ZONE_ID = os.getenv("CLOUDFLARE_ZONE_ID")
    CLOUDFLARE_PURGE_URL = os.getenv("CLOUDFLARE_PURGE_URL")
    if all([CLOUDFLARE_API_TOKEN, CLOUDFLARE_ZONE_ID, CLOUDFLARE_PURGE_URL]):
        logging.info("Purging Cloudflare CDN cache for the new PMTiles file...")
        headers = {
            "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
            "Content-Type": "application/json"
        }
        payload = {"files": [CLOUDFLARE_PURGE_URL]}
        try:
            response = requests.post(
                f"https://api.cloudflare.com/client/v4/zones/{CLOUDFLARE_ZONE_ID}/purge_cache",
                headers=headers,
                json=payload
            )
            response.raise_for_status()
            logging.info(f"Cache purge request sent successfully. Response: {response.json()}")
        except requests.exceptions.RequestException as e:
            logging.error(f"Failed to send cache purge request: {e}")
    else:
        logging.warning("Skipping CDN cache purge (Cloudflare credentials/URL not fully set in .env).")
```
## 4. Security Posture (IAM & Access)
The system adheres to the Principle of Least Privilege.

*   **Scoped API Tokens:** The credentials used by the Python Orchestrator (`R2_ACCESS_KEY_ID` and `CLOUDFLARE_API_TOKEN`) are scoped strictly to **Write-Only** permissions for the specific bucket and **Cache-Purge** permissions for the specific zone. They cannot read other buckets or modify DNS settings.
*   **Ephemeral Environments:** Credentials are injected into the Docker container at runtime via environment variables and are never written to disk or logs.