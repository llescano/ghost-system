# ARCHITECTURE.md - Ghost System

> **ULTRATHINK Analysis**: Deep architectural analysis of the Ghost System - a decentralized ESP32-based security system prioritizing resilience, distributed intelligence, and seamless migration paths.

---

## 1. System Overview

### 1.1 Architectural Diagram

```
+============================================================================+
|                         GHOST SYSTEM ARCHITECTURE                          |
+============================================================================+

                              +----------------+
                              |   Supabase     |
                              |   (Backend)    |
                              +-------+--------+
                                      |
                                      | WiFi/IP
                                      |
+------------------------+            |            +------------------------+
|    FIRMWARE GATEWAY    |<----------+----------->|    MOBILE APP /        |
|                        |     WiFi / ESP-Now     |    TELEGRAM MINI APP   |
|  +------------------+  |            |            +------------------------+
|  |   controller     |  |            |
|  +--------+---------+  |            |
|           |            |            |
|  +--------v---------+  |            |
|  |      comm        |<-------------+--- ESP-Now Broadcast
|  +--------+---------+  |            |
|           |            |            |
|  +--------v---------+  |            |
|  |       ui         |  |            |
|  +------------------+  |            |
|                        |            |
|  Target: ESP32-S3-Zero |            |
|  Power: Permanent      |            |
|  IP: Yes               |            |
+------------------------+            |
                                      |
                    +-----------------+------------------+
                    |                 |                  |
           +--------v----+    +-------v-----+    +-------v-----+
           |   SENSOR    |    |   SENSOR    |    |   SENSOR    |
           |             |    |             |    |             |
           | sensor_core |    | sensor_core |    | sensor_core |
           |    comm     |    |    comm     |    |    comm     |
           |     ui      |    |     ui      |    |     ui      |
           |             |    |             |    |             |
           | C3-Zero     |    | C3-Zero     |    | C3-Zero     |
           | Battery     |    | Battery     |    | Battery     |
           | No IP       |    | No IP       |    | No IP       |
           +-------------+    +-------------+    +-------------+

+============================================================================+
|                     "GHOST BRAIN" - DISTRIBUTED STATE                      |
|  The system has NO physical central. Intelligence is distributed.          |
+============================================================================+
```

### 1.2 Core Principles

| Principle | Description |
|-----------|-------------|
| **Distributed Intelligence** | Rules live "in the air" - devices make local decisions |
| **Backend Agnostic** | JSONB storage supports any future device type |
| **Hybrid Connectivity** | Sensors use ESP-Now (low power), Gateways use WiFi/Mesh |
| **Ghost Central** | No physical central - logical entity distributed across nodes |

---

## 2. Device Type Comparison

| Characteristic | Gateway | Sensor |
|---------------|---------|--------|
| **MCU Target** | ESP32-S3-Zero | ESP32-C3-Zero |
| **Power Source** | Permanent (USB/DC) | Battery (sleep modes) |
| **Network Role** | IP endpoint + ESP-Now hub | ESP-Now client only |
| **IP Address** | Yes (WiFi STA/AP) | No |
| **Data Persistence** | Full NVS + Backend sync | NVS only (pairing info) |
| **Actuator Capability** | Yes (siren, relay, etc.) | No (sensor only) |
| **Repeater Role** | Yes ("Civic Duty") | No |
| **LED GPIO** | GPIO 21 (WS2812) | GPIO 8 (WS2812) |
| **Boot Button GPIO** | GPIO 0 | GPIO 9 |
| **Sleep Mode** | No (always on) | Yes (deep sleep) |
| **Heartbeat Interval** | N/A | 60 seconds |
| **Backend Registration** | First-class citizen | Stored as JSONB in system |

---

## 3. Component Architecture

### 3.1 Gateway Components

```
firmware_gateway/
├── main/
│   ├── main.c                    # Entry point, task creation
│   └── includes/
│       └── system_globals.h      # Ghost Brain structure
├── components/
│   ├── controller/               # Core logic
│   │   ├── controller.c
│   │   ├── controller.h
│   │   └── CMakeLists.txt
│   ├── comm/                     # Communication layer
│   │   ├── comm.c
│   │   ├── comm.h
│   │   ├── esp_now_gateway.c
│   │   ├── wifi_manager.c
│   │   └── CMakeLists.txt
│   └── ui/                       # User interface
│       ├── ui.c
│       ├── ui.h
│       ├── led_manager.c
│       └── CMakeLists.txt
└── CMakeLists.txt
```

### 3.2 Sensor Components

```
firmware_sensor/
├── main/
│   ├── main.c                    # Entry point, task creation
│   └── includes/
│       └── system_globals.h      # Sensor context structure
├── components/
│   ├── sensor_core/              # Sensor logic
│   │   ├── sensor_core.c
│   │   ├── sensor_core.h
│   │   └── CMakeLists.txt
│   ├── comm/                     # Communication layer
│   │   ├── comm.c
│   │   ├── comm.h
│   │   ├── esp_now_sensor.c
│   │   └── CMakeLists.txt
│   └── ui/                       # User interface
│       ├── ui.c
│       ├── ui.h
│       └── CMakeLists.txt
└── CMakeLists.txt
```

### 3.3 Shared Code Opportunities

| Component | Shared? | Notes |
|-----------|---------|-------|
| `esp_now_common.c` | Yes | Common ESP-Now init, JSON parsing |
| `protocol.h` | Yes | Message structures, enums |
| `led_patterns.h` | Yes | LED indicator patterns |
| `nvs_helpers.c` | Yes | NVS read/write utilities |
| `system_globals.h` | No | Different context structures |

---

## 4. Ghost Brain (system_context_t)

### 4.1 Gateway Context Structure

```c
typedef struct {
    // === SYSTEM STATE ===
    system_state_t current_state;       // DISARMED, ARMED, ALARM, TAMPER
    system_state_t previous_state;      // For transition logic
    boot_mode_t boot_mode;              // LAST_STATE, FORCE_DISARMED, FORCE_ARMED
    
    // === SENSOR REGISTRY ===
    sensor_info_t sensors[MAX_SENSORS]; // Array of registered sensors (16 max)
    uint8_t sensor_count;               // Active sensor count
    
    // === FRTOS COMMUNICATION ===
    QueueHandle_t controller_queue;     // Message queue (10 items)
    SemaphoreHandle_t mutex;            // Thread-safe access
    
    // === DEVICE INFO ===
    char device_id[16];                 // Unique gateway ID
    
#ifdef USE_MESH_LITE
    uint8_t mesh_layer;                 // Future: Mesh layer
    uint8_t mesh_is_root;               // Future: Root node flag
#endif
} system_context_t;
```

### 4.2 Sensor Context Structure

```c
typedef struct {
    // === SWITCH STATE ===
    switch_state_t current_state;       // OPEN, CLOSED
    switch_state_t previous_state;      // For change detection
    uint32_t last_change_time;          // Tick count of last change
    
    // === GATEWAY CONNECTION ===
    gateway_status_t gateway_status;    // NOT_PAIRED, PAIRED, CONNECTED
    char gateway_id[16];                // Paired gateway ID
    uint8_t gateway_channel;            // WiFi channel
    uint32_t last_ack_time;             // Last acknowledgment
    
    // === FRTOS COMMUNICATION ===
    QueueHandle_t event_queue;          // Local event queue (5 items)
    SemaphoreHandle_t mutex;            // Thread-safe access
    
    // === DEVICE INFO ===
    char device_id[16];                 // Unique sensor ID
    device_type_t device_type;          // DOOR, PIR, KEYPAD
    
    // === BATTERY STATUS ===
    uint8_t battery_level;              // 0-100%
    uint16_t battery_voltage_mv;        // Millivolts
    
    // === COUNTERS ===
    uint32_t events_sent;               // Events transmitted
    uint32_t events_acked;              // Events confirmed
    uint32_t heartbeats_sent;           // Heartbeats sent
} sensor_context_t;
```

### 4.3 Mutex Protection Strategy

```
+-------------------+     +------------------+
|     Task A        |     |     Task B       |
+--------+----------+     +--------+---------+
         |                         |
         v                         v
+--------+----------+     +--------+---------+
| system_context_   |     | system_context_  |
| lock(100ms)       |     | lock(100ms)      |
+--------+----------+     +--------+---------+
         |                         |
         |    +---------------+    |
         +--->|    MUTEX      |<---+
              |  (Binary      |
              |   Semaphore)  |
              +-------+-------+
                      |
                      v
              +-------+-------+
              | gSystemCtx    |
              | Access        |
              +-------+-------+
                      |
                      v
              +-------+-------+
              | system_context|
              | _unlock()     |
              +---------------+

RULES:
1. ALWAYS use mutex for state read/write
2. Timeout: 100ms typical, portMAX_DELAY for critical paths
3. Never hold mutex during I/O operations
4. Queue messages are copied, no mutex needed after send
```

### 4.4 Queue-Based Message Passing

```
                    GATEWAY MESSAGE FLOW

+----------+     +----------------+     +------------+
|  comm    |---->| xControllerQueue|---->| controller |
|  task    |     |   (10 items)   |     |   task     |
+----------+     +----------------+     +------------+
     |                                          |
     | ESP-Now                                  | Process
     | Receive                                  | Message
     v                                          v
+----------+                            +------------+
| Parse    |                            | Update     |
| JSON     |                            | State      |
+----------+                            +------------+


                    SENSOR MESSAGE FLOW

+----------+     +---------------+     +------------+
| sensor   |---->| xEventQueue   |---->| comm       |
| task     |     |  (5 items)    |     | task       |
+----------+     +---------------+     +------------+
     |                                          |
     | Debounce                                 | Send
     | Detect                                   | ESP-Now
     v                                          v
+----------+                            +------------+
| Queue    |                            | Transmit   |
| Event    |                            | JSON       |
+----------+                            +------------+
```

---

## 5. Boot Modes

### 5.1 Boot Mode Definitions

| Mode | Value | Description | Use Case |
|------|-------|-------------|----------|
| `BOOT_MODE_LAST_STATE` | 0 | Restore previous state from NVS | Normal operation |
| `BOOT_MODE_FORCE_DISARMED` | 1 | Always start disarmed | Maintenance mode |
| `BOOT_MODE_FORCE_ARMED` | 2 | Always start armed | High-security mode |

### 5.2 NVS Storage Strategy

```
NVS Namespace: "sys_cfg" (Gateway) / "sensor_cfg" (Sensor)

+-------------------+------------------+------------------+
| Key               | Type             | Description      |
+-------------------+------------------+------------------+
| boot_mode         | uint8_t          | Boot mode enum   |
| last_state        | uint8_t          | Last known state |
| sensor_id         | string[16]       | Sensor ID        |
| gateway_id        | string[16]       | Paired gateway   |
| switch_state      | uint8_t          | Last switch state|
+-------------------+------------------+------------------+
```

### 5.3 Boot Sequence Flow

```
                    GATEWAY BOOT SEQUENCE

+------------+     +------------+     +------------+
| Power On   |---->| Init NVS   |---->| Init Context|
+------------+     +------------+     +------------+
                                           |
                                           v
                                   +------------+
                                   | Read NVS   |
                                   | boot_mode  |
                                   +------------+
                                           |
                     +---------------------+---------------------+
                     |                     |                     |
                     v                     v                     v
            +------------+        +------------+        +------------+
            |LAST_STATE  |        |FORCE_      |        |FORCE_      |
            |            |        |DISARMED    |        |ARMED       |
            +------------+        +------------+        +------------+
                     |                     |                     |
                     v                     |                     |
            +------------+                 |                     |
            | Read       |                 |                     |
            | last_state |                 |                     |
            +------------+                 |                     |
                     |                     |                     |
                     +---------------------+---------------------+
                                           |
                                           v
                                   +------------+
                                   | Init Comm  |
                                   | ESP-Now    |
                                   +------------+
                                           |
                                           v
                                   +------------+
                                   | Create     |
                                   | Tasks      |
                                   +------------+
```

### 5.4 Recovery Mechanisms

| Failure Mode | Detection | Recovery Action |
|--------------|-----------|-----------------|
| NVS corrupt | `ESP_ERR_NVS_NO_FREE_PAGES` | Erase and reinitialize NVS |
| Lost state | Invalid state value | Default to DISARMED |
| Sensor timeout | No heartbeat for N intervals | Mark sensor offline |
| Gateway lost (sensor) | No ACK for N messages | Enter safe mode (DISARMED) |

---

## 6. JSON Communication Protocol

### 6.1 Message Structure

```json
{
  "header": {
    "ver": 1,
    "ts": 1698765432,
    "src_id": "SENSOR_01",
    "src_type": "SEC_SENSOR"
  },
  "payload": {
    "type": "EVENT",
    "action": "STATE_CHANGE",
    "value": "OPEN"
  }
}
```

### 6.2 Header Fields

| Field | Type | Description |
|-------|------|-------------|
| `ver` | uint8 | Protocol version (currently 1) |
| `ts` | uint32 | Unix timestamp (gateway) or tick count (sensor) |
| `src_id` | string[16] | Source device ID |
| `src_type` | string | Device type: `GATEWAY`, `SEC_SENSOR`, `PIR_SENSOR` |

### 6.3 Payload Types

| Type | Direction | Description |
|------|-----------|-------------|
| `EVENT` | Sensor → Gateway | State change notification |
| `COMMAND` | Gateway → Sensor | Arm/Disarm/Status request |
| `STATUS` | Both | Heartbeat or status response |
| `ACK` | Both | Message acknowledgment |
| `PAIR_REQ` | Sensor → Gateway | Pairing request |
| `PAIR_RESP` | Gateway → Sensor | Pairing response |

### 6.4 Message Examples

#### Sensor Event (Door Opened)
```json
{
  "header": {"ver": 1, "ts": 1698765432, "src_id": "SENSOR_01", "src_type": "SEC_SENSOR"},
  "payload": {"type": "EVENT", "action": "STATE_CHANGE", "value": "OPEN", "battery": 85}
}
```

#### Arm Command
```json
{
  "header": {"ver": 1, "ts": 1698765500, "src_id": "GATEWAY_01", "src_type": "GATEWAY"},
  "payload": {"type": "COMMAND", "action": "ARM", "value": 0}
}
```

#### Heartbeat
```json
{
  "header": {"ver": 1, "ts": 1698765600, "src_id": "SENSOR_01", "src_type": "SEC_SENSOR"},
  "payload": {"type": "STATUS", "action": "HEARTBEAT", "value": "CLOSED", "battery": 85}
}
```

#### Acknowledgment
```json
{
  "header": {"ver": 1, "ts": 1698765433, "src_id": "GATEWAY_01", "src_type": "GATEWAY"},
  "payload": {"type": "ACK", "action": "EVENT_ACK", "value": 0}
}
```

---

## 7. Implementation Phases

### Phase 1: Core Infrastructure
**Complexity: Medium**

| Task | Project | Priority |
|------|---------|----------|
| Create `controller` component | Gateway | High |
| Create `sensor_core` component | Sensor | High |
| Implement state machine | Gateway | High |
| Implement debounce logic | Sensor | High |
| NVS read/write helpers | Both | High |
| Mutex protection | Both | High |

### Phase 2: Communication Layer
**Complexity: High**

| Task | Project | Priority |
|------|---------|----------|
| ESP-Now initialization | Both | High |
| JSON serialization/parsing | Both | High |
| Message queue integration | Both | High |
| Pairing protocol | Both | Medium |
| ACK/retry mechanism | Both | Medium |
| "Civic Duty" repeater logic | Gateway | Low |

### Phase 3: UI and User Interaction
**Complexity: Low**

| Task | Project | Priority |
|------|---------|----------|
| LED indicator patterns | Both | Medium |
| Boot button handling | Gateway | Medium |
| State visualization | Both | Medium |
| Battery indicator | Sensor | Low |

### Phase 4: Backend Integration
**Complexity: High**

| Task | Project | Priority |
|------|---------|----------|
| WiFi manager (STA/AP) | Gateway | High |
| MQTT/HTTP client | Gateway | High |
| Supabase integration | Gateway | Medium |
| OTA updates | Gateway | Medium |
| Telegram Mini App | Backend | Low |

---

## 8. Technical Checklist

### 8.1 Gateway Firmware Tasks

- [ ] Create `components/controller/` with state machine
- [ ] Create `components/comm/` with ESP-Now + WiFi
- [ ] Create `components/ui/` with LED manager
- [ ] Implement `controller_task()` message loop
- [ ] Implement sensor registration logic
- [ ] Implement arm/disarm commands
- [ ] Implement alarm triggering logic
- [ ] Add WiFi provisioning (SoftAP)
- [ ] Add MQTT client for backend
- [ ] Add OTA update support
- [ ] Test with multiple sensors

### 8.2 Sensor Firmware Tasks

- [ ] Create `components/sensor_core/` with debounce
- [ ] Create `components/comm/` with ESP-Now
- [ ] Create `components/ui/` with LED manager
- [ ] Implement `sensor_task()` state monitoring
- [ ] Implement pairing mode
- [ ] Implement event sending with retry
- [ ] Implement heartbeat mechanism
- [ ] Add deep sleep mode
- [ ] Add battery monitoring (ADC)
- [ ] Test battery life optimization

### 8.3 Shared Code Tasks

- [ ] Create `shared/` directory for common code
- [ ] Extract `protocol.h` with message definitions
- [ ] Extract `esp_now_common.c` for init/parsing
- [ ] Extract `led_patterns.h` for LED effects
- [ ] Extract `nvs_helpers.c` for storage utilities
- [ ] Create unit tests for shared code

---

## 9. Edge Cases and Failure Modes

### 9.1 Communication Failures

| Scenario | Detection | Response |
|----------|-----------|----------|
| Sensor loses gateway | No ACK after 3 retries | Enter safe mode, retry periodically |
| Gateway loses sensor | No heartbeat for 5 min | Mark sensor offline, notify backend |
| Message corruption | JSON parse error | Ignore message, no ACK |
| Duplicate message | Same timestamp + src_id | Skip processing, send ACK |

### 9.2 State Conflicts

| Scenario | Resolution |
|----------|------------|
| Sensor sends OPEN while DISARMED | Log event, no alarm |
| Multiple sensors trigger simultaneously | Process in order, single alarm |
| Arm command during ALARM | Invalid transition, ignored |
| Disarm during ALARM | Valid, transitions to DISARMED |

### 9.3 Power Failures

| Scenario | Recovery |
|----------|----------|
| Gateway power loss | Restore from NVS on boot |
| Sensor battery critical | Send low battery alert, deep sleep |
| Sensor power restore | Resume from NVS, send heartbeat |

---

## 10. Future Considerations

### 10.1 Mesh Lite Migration

```c
// Current code should use this pattern:
#ifdef USE_MESH_LITE
    // Mesh Lite implementation
    esp_mesh_lite_send(dest, data, len);
#else
    // ESP-Now implementation
    esp_now_send(dest_mac, data, len);
#endif
```

### 10.2 Security Enhancements (Future)

- [ ] Encrypted ESP-Now messages
- [ ] Device authentication tokens
- [ ] Secure pairing protocol
- [ ] Tamper detection and reporting

### 10.3 Scalability Considerations

- Current: 16 sensors per gateway
- Future: Mesh network with multiple gateways
- Backend: JSONB allows flexible device properties

---

*Document generated with ULTRATHINK protocol - Deep analysis through technical, scalability, and maintainability lenses.*
