#!/bin/bash

# 🚀 PumpSwap Trading Bot - Instalador SIN INPUT
# Instala todo y luego pide configuración LOCAL

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║     🤖 PumpSwap Trading Bot - Auto Installer 🚀      ║
║                                                      ║
║     Instalando todo automáticamente...              ║
║     (Configuración después de la instalación)       ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Detectar OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
else
    OS="windows"
fi
echo -e "${BLUE}🔧 Sistema: $OS${NC}"

# Instalar Node.js si no existe
if ! command -v node &> /dev/null || [ "$(node --version | cut -d'v' -f2 | cut -d'.' -f1)" -lt 18 ]; then
    echo -e "${BLUE}🔧 Instalando Node.js...${NC}"
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &>/dev/null
        sudo apt-get install -y nodejs &>/dev/null
    elif [[ "$OS" == "mac" ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
        fi
        brew install node &>/dev/null
    fi
    echo -e "${GREEN}✅ Node.js instalado: $(node --version)${NC}"
else
    echo -e "${GREEN}✅ Node.js OK: $(node --version)${NC}"
fi

# Instalar Rust si no existe
if ! command -v cargo &> /dev/null; then
    echo -e "${BLUE}🔧 Instalando Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
    source $HOME/.cargo/env
    echo -e "${GREEN}✅ Rust instalado: $(cargo --version)${NC}"
else
    echo -e "${GREEN}✅ Rust OK: $(cargo --version)${NC}"
fi

# Crear proyecto
echo -e "${BLUE}🔧 Creando proyecto...${NC}"
rm -rf pumpswap-bot 2>/dev/null || true
mkdir -p pumpswap-bot/{detector/src,executor}
cd pumpswap-bot

# Descargar archivos desde GitHub
echo -e "${BLUE}🔧 Descargando archivos del proyecto...${NC}"

# package.json
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/package.json -o executor/package.json

# Cargo.toml
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/Cargo.toml -o detector/Cargo.toml

# index.js
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/index.js -o executor/index.js

# testTrade.js
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/testTrade.js -o executor/testTrade.js

# main.rs
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/main.rs -o detector/src/main.rs

# configurator.js
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/configurator.js -o configurator.js

# Scripts
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/run.sh -o run.sh
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/templates/test.sh -o test.sh

chmod +x run.sh test.sh configurator.js

# .env template
cat > executor/.env.template << 'EOF'
# Configuración de Wallet y RPC
PAYER_SECRET=[TU_WALLET_ARRAY_AQUI]
RPC_URL=https://api.mainnet-beta.solana.com

# Configuración de Telegram
TELEGRAM_TOKEN=TU_BOT_TOKEN_AQUI
TELEGRAM_CHAT_ID=TU_CHAT_ID_AQUI

# Configuración de Trading
TAKE_PROFIT_PCT=0.40
STOP_LOSS_PCT=0.10
CHECK_INTERVAL_MS=15000

# API Keys
SHYFT_API_KEY=TU_SHYFT_API_KEY_AQUI
HELIUS_API_KEY=3724fd61-91e7-4863-a1a5-53507e3a122f
EOF

# README
cat > README.md << 'EOF'
# 🤖 PumpSwap Trading Bot

## 🚀 Instalación Completada

### Paso 1: Configurar
```bash
node configurator.js
```

### Paso 2: Ejecutar
```bash
./run.sh
```

### Paso 3: Probar
```bash
./test.sh
```

## 📁 Archivos Importantes

- `executor/.env` - Tu configuración
- `run.sh` - Ejecutar el bot
- `test.sh` - Probar conexiones
- `configurator.js` - Configurador interactivo

¡Happy trading! 🚀
EOF

# Instalar dependencias
echo -e "${BLUE}🔧 Instalando dependencias Node.js...${NC}"
cd executor
npm install --silent &>/dev/null || npm install
cd ..

# Compilar Rust
echo -e "${BLUE}🔧 Compilando detector Rust...${NC}"
cd detector
export PATH="$HOME/.cargo/bin:$PATH"
cargo build --release --quiet &>/dev/null || cargo build --release
cd ..

echo ""
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║         🎉 ¡INSTALACIÓN COMPLETADA! 🎉               ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}📋 Próximos pasos:${NC}"
echo ""
echo -e "${BLUE}1️⃣ Ir al directorio:${NC}"
echo "   cd pumpswap-bot"
echo ""
echo -e "${BLUE}2️⃣ Configurar tu bot:${NC}"
echo "   node configurator.js"
echo ""
echo -e "${BLUE}3️⃣ Ejecutar el bot:${NC}"
echo "   ./run.sh"
echo ""
echo -e "${GREEN}🎯 ¡Tu bot está listo para configurar!${NC}"
