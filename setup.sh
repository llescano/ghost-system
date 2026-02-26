#!/bin/bash
# Script para inicializar submódulos Git de Ghost System

set -e

echo "👻 Inicializando repositorios de Ghost System..."
echo ""

# Crear estructura de directorios
echo "📁 Creando estructura de directorios..."
mkdir -p firmware backend webapp docs

# Agregar submódulos
echo "📦 Agregando submódulos Git..."

# Nota: Estos repos se crearán después
# Por ahora, solo preparamos la estructura

echo "✅ Estructura creada"
echo ""
echo "Para completar la setup, ejecuta:"
echo "  git init"
echo "  git add ."
echo "  git commit -m 'Initial commit'"
echo ""
echo "Luego, cuando los repos hijos existan:"
echo "  git submodule add https://github.com/luisfiorentino/ghost-firmware-gateway.git firmware/gateway"
echo "  git submodule add https://github.com/luisfiorentino/ghost-firmware-sensor.git firmware/sensor"
echo "  git submodule add https://github.com/luisfiorentino/ghost-backend-supabase.git backend"
echo "  git submodule add https://github.com/luisfiorentino/ghost-webapp.git webapp"
