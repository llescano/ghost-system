Sí, tengo el contenido de la versión anterior perfectamente referenciado. Has hecho bien en pedir esta revisión porque, aunque el nuevo PRD es mucho más robusto a nivel arquitectónico ("El Gran Plan"), la versión anterior tenía **detalles finos de implementación técnica** (el "cómo") que se pueden perder al ver el bosque completo.

He detectado **4 puntos clave** de la versión anterior que no están explícitos en el nuevo documento y son vitales para el agente de código:

1.  **Lógica de Inicio (Boot Modes):** En el nuevo PRD falta definir qué pasa cuando el dispositivo se reinicia (¿Recupera el último estado? ¿Fuerza desarmado?).
2.  **Detalles de RTOS:** La versión anterior especificaba el uso de `xQueue` para la comunicación entre tareas y `Mutex` para el `system_context`.
3.  **Alcance del MVP:** La versión anterior aclaraba que se empieza con "Wi-Fi Estación" y luego se migra a "Mesh Lite" (usando un `#define`). El nuevo PRD lo menciona, pero no como una directiva de desarrollo.
4.  **Hardware Específico:** Pines del LED WS2812 en las placas Waveshare.

### Propuesta: Versión Final Unificada

Aquí tienes la versión definitiva de `PRD_Ghost_System.md` que **integra todo**: la arquitectura del Ghost System + los detalles técnicos de implementación del MVP. Con esto puedes borrar el archivo anterior tranquilamente.

```markdown
# PRD: Sistema de Seguridad y Domótica "Ghost System"

## 1. Resumen del Proyecto
Desarrollo de un sistema de seguridad y domótica **descentralizado** basado en ESP32. El sistema elimina el concepto de "central física", reemplazándolo por una **"Central Fantasma" (Ghost System)**, una entidad lógica distribuida entre los nodos.

**Principios Fundamentales:**
1.  **Inteligencia Distribuida:** Las reglas viven "en el aire". Los dispositivos toman decisiones locales basadas en el estado global.
2.  **Agnosticismo de Backend:** Base de datos flexible (JSONB) para soportar cualquier dispositivo futuro.
3.  **Híbrido de Conectividad:** Sensores usan ESP-Now (bajo consumo), Gateways usan Wi-Fi/Mesh (alto ancho de banda).

---

## 2. Arquitectura de Hardware

### Hardware MVP (Prototipo)
*   **MCU:** Waveshare ESP32-C3-Zero / ESP32-S3-Zero.
*   **Interfaz:** LED WS2812 integrado.
    *   *Pin C3:* GPIO 8.
    *   *Pin S3:* GPIO 21.
*   **Dependencias IDF:** `espressif/led_indicator`, `espressif/cjson`.

### Clasificación de Dispositivos

#### A. Gateways (Ciudadanos de Primera Clase)
Dispositivos alimentados permanentemente con IP propia.
*   **Roles:** Actuadores, Repetidores (Repeaters), Traductores (RF/IP).
*   **Ejemplos:** Sirena Inteligente, Enchufe Wi-Fi, Control de Riego, Expansor de Zonas.

#### B. Nodos Dependientes (Habitantes)
Dependen de un Gateway para comunicarse. No tienen IP.
*   **Registro:** Se guardan como propiedades (JSONB) dentro del Sistema Ghost.
*   **Ejemplos:** Sensores batería, Controles remotos ESP-Now, Actuadores de relé remotos.

---

## 3. Arquitectura de Software (Firmware)

### Estructura de Proyectos
Dos proyectos ESP-IDF separados:
1.  `firmware_gateway/`
2.  `firmware_sensor/`

### Detalles de Implementación (RTOS)
El firmware utiliza FreeRTOS con un diseño desacoplado:
*   **Sincronización:** Uso de **Colas (`xQueue`)** para paso de mensajes entre tareas (ej. Comm -> Controller).
*   **Protección:** Uso de **Mutex** para acceso a la estructura global `gSystemCtx`.
*   **Boot Mode:** El dispositivo debe soportar configuración de inicio:
    *   `LAST_STATE`: Recupera el estado anterior tras un reinicio.
    *   `FORCE_DISARMED`: Inicia siempre desarmado.
    *   `FORCE_ARMED`: Inicia siempre armado.

### Módulos Principales (Gateway)
1.  **Controller:** Lógica central, recibe eventos de una cola unificada (`xControllerQueue`).
2.  **Comm:** Maneja Wi-Fi y ESP-Now. Implementa el "Deber Cívico" de repetir mensajes ajenos.
3.  **UI:** Gestiona LEDs usando el componente `led_indicator` (backend RMT).

### Estrategia de Conectividad (MVP -> Producción)
*   **Fase MVP:** Wi-Fi Estación (STA) + ESP-Now. Fácil de depurar.
*   **Fase Producción:** Integración de **Mesh Lite**.
    *   *Preparación:* El código de `comm` debe usar un `#define USE_MESH_LITE` para alternar entre la implementación Wi-Fi simple y la malla sin cambiar la lógica de negocio.

### Protocolo de Comunicación (JSON)
```json
{
  "header": { "ver": 1, "ts": 1698765432, "src_id": "SENSOR_01" },
  "payload": { "type": "EVENT", "action": "STATE_CHANGE", "value": "OPEN" }
}
```

---

## 4. Arquitectura de Datos (Supabase/PostgreSQL)

### Tabla: `systems` (El Sistema Ghost)
Contiene la lógica y el estado central.
```sql
CREATE TABLE systems (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    status VARCHAR(20) DEFAULT 'DISARMED', -- Estado Global
    nodes JSONB DEFAULT '[]'   -- Sensores dependientes (Habitantes)
);
```
*   **Campo `nodes`:** Guarda sensores y su configuración particular (ej. `beep_on_open`).

### Tabla: `devices` (Físicos)
Gateways y Centrales Físicas.
```sql
CREATE TABLE devices (
    id UUID PRIMARY KEY,
    system_id UUID REFERENCES systems(id),
    type VARCHAR(20), -- "GATEWAY_SIREN", "GATEWAY_PLUG"
    state JSONB DEFAULT '{}' -- Online, RSSI, Diagnóstico
);
```

---

## 5. Lógica de Comportamiento (Reglas "En el Aire")

### Regla de Repetición (Deber Cívico)
Todo Gateway debe retransmitir mensajes ESP-Now que no sean para sí mismo, inyectándolos en la red IP/Mesh para asegurar la cobertura en puntos lejanos (ej. Quincho).

### Configuración Distribuida
Los dispositivos actuadores (Sirenas, Luces) consultan su configuración local (`config.beep_on_arm`) ante un evento global para decidir si actúan o ignoran. Esto permite personalizar el comportamiento de cada dispositivo dentro del mismo sistema.

---

## 6. Flujos de Usuario

### Provisioning (Configuración Inicial)
1.  **Modo AP:** El dispositivo crea red propia.
2.  **Portal Cautivo:** Usuario introduce credenciales Wi-Fi.
3.  **Token de Vinculación:** Dispositivo obtiene token de Supabase y lo muestra. Usuario lo carga en Telegram.

### Vinculación de Nodos (Sensores Batería)
1.  **Modo Aprendizaje:** App activa `LEARNING_MODE` en el Sistema Ghost.
2.  **Emparejamiento:** Sensor se enciende, Gateway cercano lo adopta (RSSI).
3.  **Registro:** Gateway informa al Backend.

### Interfaz de Usuario (Telegram Mini App)
*   Web App dentro de Telegram.
*   UI dinámica basada en JSON.
*   Sin necesidad de publicar en App Stores.
```