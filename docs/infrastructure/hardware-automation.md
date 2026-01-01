# Temporal Computing: Hardware Orchestration

Instead of paying for 24/7 cloud servers, Sentinel uses a "Temporal" pattern to minimize costs while using maximum power.

### Lifecycle of the Node
1. **03:00 AM:** ACPI Wake Timers resume the i9 node from S4 Hibernate.
2. **The Handshake:** A Python controller polls the Docker socket, waiting for the daemon to re-mount volumes after the wake event.
3. **Execution:** The node runs the full ETL pipeline at 200+ tiles/sec.
4. **Hibernation:** A WSL-to-Windows interop command (`shutdown.exe /h`) returns the hardware to 0-watt consumption immediately upon R2 upload verification.