CREATE TABLE IF NOT EXISTS sentinel_analytics.patrol_events
(
    -- === CORE DIMENSIONS ===
    event_id String,
    patrol_id UInt64,
    officer_id UInt64,
    event_timestamp DateTime,
    event_date Date,
    event_type String,

    -- === DENORMALIZED CONTEXT ===
    station_id UInt64,
    vehicle_id Nullable(UInt64),
    
    -- --- Location Data ---
    latitude Nullable(Float64),
    longitude Nullable(Float64),
    accuracy Nullable(Float64),
    speed Nullable(Float64),
    heading Nullable(Float64),

    -- === FLATTENED EVENT-SPECIFIC FIELDS ===

    -- -- From Hotspot & Remark --
    hotspot_id Nullable(UInt64),
    remark_text Nullable(String),
    remark_length Nullable(UInt32),
    new_priority_ranking Nullable(Int32),
    visited_hotspots Array(Nullable(UInt64)),
    
    -- -- From VehicleChecking --
    vehicle_plate_number Nullable(String),
    suspicious_activity Nullable(UInt8), -- Use UInt8 for booleans (0 or 1)
    suspicion_details Nullable(String),
    
    -- -- From StrangerEncounter --
    stranger_name Nullable(String),
    stranger_purpose Nullable(String),
    stranger_id_type Nullable(String),
    stranger_id_details Nullable(String),
    
    -- -- From EmergencyIncident --
    emergency_category Nullable(String),

    -- -- From Feedback --
    feedback_text Nullable(String),

    -- -- From GeofenceLog --
    geofence_event_type Nullable(String),
    
    -- -- From PatrolLog --
    patrol_status_at_event Nullable(String),
    hotspots_to_visit Array(Nullable(UInt64)),
    assigned_crew_ids Array(Nullable(UInt32)),

    -- === ANALYTICAL METRICS ===
    base_risk_score Float64 DEFAULT 0.0,

    -- === CATCH-ALL FOR COMPLEX/NESTED DATA ===
    details_json Nullable(String),
    media_ref Nullable(String)

)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, station_id, officer_id, event_type, event_timestamp);