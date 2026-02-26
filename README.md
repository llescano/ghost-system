# 👻 Ghost System

Sistema de seguridad y domótica decentralizado basado en ESP32.

## 🏗️ Arquitectura

```
ghost-system/
├── firmware/       # Submódulos → firmware específicos
├── backend/        # Submódulo → Edge Functions Supabase
├── webapp/         # Submódulo → Web App / Telegram Mini App
└── docs/           # Documentación del proyecto
```

## 📦 Componentes

| Componente | Descripción | Estado |
|------------|-------------|--------|
| **Gateway** | ESP32-S3 con Wi-Fi + ESP-Now | ✅ MVP |
| **Sensor** | Sensores batería ESP32-C3 | 🔄 Pendiente |
| **Backend** | Supabase Edge Functions | ✅ MVP |
| **WebApp** | Monitor de estado + Telegram Mini App | ✅ MVP |

## 🔗 Links

- **Documentación PRD**: [PRD_Ghost_System.md](../PRD_Ghost_System.md)
- **Arquitectura**: [ARCHITECTURE.md](../ARCHITECTURE.md)
- **Hardware**: [HARDWARE.md](../HARDWARE.md)

## 📝 Notas

Este monorepo utiliza **submódulos de Git** para organizar el código:
- `firmware/gateway` → [`ghost-firmware-gateway`](https://github.com/luisfiorentino/ghost-firmware-gateway)
- `firmware/sensor` → [`ghost-firmware-sensor`](https://github.com/luisfiorentino/ghost-firmware-sensor)
- `backend` → [`ghost-backend-supabase`](https://github.com/luisfiorentino/ghost-backend-supabase)
- `webapp` → [`ghost-webapp`](https://github.com/luisfiorentino/ghost-webapp)

## 🚀 Quick Start

```bash
# Clonar el monorepo con submódulos
git clone --recursive https://github.com/luisfiorentino/ghost-system.git
cd ghost-system

# Actualizar submódulos
git submodule update --remote --merge
```

## 📄 Licencia

MIT License - Ver LICENSE para más detalles.
