#!/bin/bash

# 🔧 PumpSwap Trading Bot - Instalador que FUNCIONA
# Descarga el script completo y luego lo ejecuta para evitar problemas con input

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║     🤖 PumpSwap Trading Bot - Instalador 🚀          ║
║                                                      ║
║     Descargando e instalando automáticamente...     ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}📥 Descargando instalador completo...${NC}"

# Descargar el script completo
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/mega-installer.sh -o pumpswap-installer.sh

# Hacer ejecutable
chmod +x pumpswap-installer.sh

echo -e "${GREEN}✅ Descarga completa${NC}"
echo -e "${BLUE}🚀 Ejecutando instalador...${NC}"
echo ""

# Ejecutar el instalador
./pumpswap-installer.sh

# Limpiar
rm -f pumpswap-installer.sh

echo -e "${GREEN}🎉 ¡Instalación completada!${NC}"
