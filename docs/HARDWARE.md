# Documentación de Hardware

## ESP32-C3-Zero (Sensor)

### Especificaciones
- **MCU:** ESP32-C3FH4 (RISC-V 160MHz, 4MB Flash)
- **USB:** Native USB (JTAG directo, sin chip USB-UART)
- **Puerto:** COM23

### GPIOs
| Función | GPIO | Notas |
|---------|------|-------|
| WS2812 RGB LED | GPIO10 | LED de estado/indicación |
| BOOT Button | GPIO9 | Usado como sensor simulado |
| USB D- | GPIO18 | - |
| USB D+ | GPIO19 | - |

### Programación
1. Presionar y mantener BOOT (GPIO9)
2. Conectar cable Type-C
3. Soltar BOOT
4. `idf.py -p COM23 flash`

### Uso en el Proyecto
- **Botón BOOT (GPIO9):** Simula el sensor de puerta/ventana
  - Presionado = CLOSED (cerrado)
  - Soltado = OPEN (abierto)
- **LED WS2812 (GPIO10):** Indicador de estado
  - Verde sólido: Disarmado
  - Rojo sólido: Armado
  - Rojo parpadeando: Alarma
  - Azul: Buscando gateway
  - Amarillo: Error de comunicación

---

## ESP32-S3-Zero (Gateway)

### Especificaciones
- **MCU:** ESP32-S3FN8 (Xtensa LX7 240MHz, 8MB Flash, 2MB PSRAM)
- **USB:** Native USB (JTAG directo, sin chip USB-UART)
- **Puerto:** COM22

### GPIOs
| Función | GPIO | Notas |
|---------|------|-------|
| WS2812 RGB LED | GPIO21 | LED de estado/indicación |
| BOOT Button | GPIO0 | Botón de arranque |
| USB D- | GPIO19 | - |
| USB D+ | GPIO20 | - |

### Programación
1. Presionar y mantener BOOT (GPIO0)
2. Conectar cable Type-C
3. Soltar BOOT
4. `idf.py -p COM22 flash`

### Uso en el Proyecto
- **LED WS2812 (GPIO21):** Indicador de estado del sistema
  - Verde sólido: Sistema desarmado
  - Rojo sólido: Sistema armado
  - Rojo parpadeando: Alarma activa
  - Azul parpadeando: Buscando sensores
  - Amarillo: Error de red/WiFi

---

## Componentes Externos (Espressif)

### LED Indicator
- **Componente:** `espressif/led_indicator`
- **Versión:** >=2.1.1
- **Documentación:** https://components.espressif.com/components/espressif/led_indicator

### Button
- **Componente:** `espressif/button`
- **Versión:** >=4.1.5
- **Documentación:** https://components.espressif.com/components/espressif/button

### cJSON
- **Componente:** `espressif/cjson`
- **Versión:** *
- **Uso:** Parseo de mensajes JSON para ESP-Now

---

## Referencias

- [ESP32-C3-Zero Waveshare](https://www.waveshare.com/wiki/ESP32-C3-Zero)
- [ESP32-S3-Zero Waveshare](https://www.waveshare.com/wiki/ESP32-S3-Zero)
- [Espressif Components Registry](https://components.espressif.com)
