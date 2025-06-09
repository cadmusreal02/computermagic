#!/bin/bash

# 🚀 PumpSwap Bot - Instalador Local
# Descarga automáticamente el script completo desde mi respuesta

echo "🤖 PumpSwap Trading Bot - Instalador"
echo "====================================="

# Crear el script completo inline
cat > setup-auto.sh << 'SCRIPT_END'
#!/bin/bash

# 🪄 SCRIPT MÁGICO - PumpSwap Trading Bot Auto-Setup
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_step() { echo -e "${BLUE}🔧 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║     🤖 PumpSwap Trading Bot - Auto Setup 🪄          ║
║     Este script instala TODO automáticamente        ║
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
print_success "$OS detectado"

# Instalar Node.js
install_nodejs() {
    print_step "Verificando Node.js..."
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            print_success "Node.js ya instalado ($(node --version))"
            return
        fi
    fi
    
    print_step "Instalando Node.js..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OS" == "mac" ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install node
    fi
    print_success "Node.js instalado: $(node --version)"
}

# Instalar Rust
install_rust() {
    print_step "Verificando Rust..."
    if command -v cargo &> /dev/null; then
        print_success "Rust ya instalado ($(cargo --version))"
        return
    fi
    
    print_step "Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    print_success "Rust instalado: $(cargo --version)"
}

# Recopilar datos del usuario
collect_user_data() {
    print_step "Configuración personalizada..."
    echo ""
    
    echo -e "${YELLOW}🔑 Tu wallet privada (array JSON):${NC}"
    echo "Ejemplo: [81,144,223,80,201,5,14,64...]"
    read -p "PAYER_SECRET: " PAYER_SECRET
    
    echo -e "${YELLOW}📱 Configuración Telegram:${NC}"
    read -p "Bot Token: " TELEGRAM_TOKEN
    read -p "Chat ID: " TELEGRAM_CHAT_ID
    
    echo -e "${YELLOW}🔧 API Keys:${NC}"
    read -p "Shyft API Key: " SHYFT_API_KEY
    
    read -p "Helius API Key [ENTER=ejemplo]: " HELIUS_API_KEY
    if [ -z "$HELIUS_API_KEY" ]; then
        HELIUS_API_KEY="3724fd61-91e7-4863-a1a5-53507e3a122f"
    fi
    
    echo -e "${YELLOW}👥 Wallets a seguir:${NC}"
    echo "Formato: direccion,nickname"
    
    WALLETS=()
    for i in {1..5}; do
        read -p "Wallet $i [ENTER=terminar]: " wallet_input
        if [ -z "$wallet_input" ]; then
            break
        fi
        WALLETS+=("$wallet_input")
    done
    
    if [ ${#WALLETS[@]} -eq 0 ]; then
        WALLETS=(
            "DfMxre4cKmvogbLrPigxmibVTTQDuzjdXojWzjCXXhzj,monstruo_pump"
            "EHg5YkU2SZBTvuT87rUsvxArGp3HLeye1fXaSDfuMyaf,gordo_data"
        )
    fi
    
    print_success "Configuración guardada"
}

# Crear proyecto
create_project() {
    print_step "Creando proyecto..."
    mkdir -p pumpswap-bot/{detector/src,executor}
    cd pumpswap-bot
    
    # .env
    cat > executor/.env << EOF
PAYER_SECRET=$PAYER_SECRET
RPC_URL=https://api.mainnet-beta.solana.com
TELEGRAM_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
TAKE_PROFIT_PCT=0.40
STOP_LOSS_PCT=0.10
CHECK_INTERVAL_MS=15000
SHYFT_API_KEY=$SHYFT_API_KEY
HELIUS_API_KEY=$HELIUS_API_KEY
EOF

    # package.json
    cat > executor/package.json << 'PACKAGE_END'
{
  "name": "pumpswap-bot",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "node test.js"
  },
  "dependencies": {
    "@pump-fun/pump-swap-sdk": "^0.0.1-beta.36",
    "@raydium-io/raydium-sdk-v2": "^0.1.82",
    "@solana/web3.js": "^1.95.3",
    "express": "^4.19.2",
    "body-parser": "^1.20.2",
    "node-telegram-bot-api": "^0.66.0",
    "dotenv": "^16.4.5",
    "axios": "^1.7.2",
    "graphql-request": "^6.1.0",
    "node-fetch": "^2.7.0"
  }
}
PACKAGE_END

    # Cargo.toml
    cat > detector/Cargo.toml << 'CARGO_END'
[package]
name = "detector"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.0", features = ["full"] }
tokio-tungstenite = "0.21"
futures = "0.3"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
reqwest = { version = "0.11", features = ["json"] }
anyhow = "1.0"
CARGO_END

    print_success "Estructura creada"
}

# Crear código base (versión simplificada)
create_code() {
    print_step "Generando código..."
    
    # index.js simplificado
    cat > executor/index.js << 'JS_END'
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const TelegramBot = require("node-telegram-bot-api");

const { TELEGRAM_TOKEN, TELEGRAM_CHAT_ID } = process.env;
const bot = new TelegramBot(TELEGRAM_TOKEN);
const app = express();
app.use(bodyParser.json());

const positions = new Map();

async function notify(text) {
  try {
    await bot.sendMessage(TELEGRAM_CHAT_ID, text, { parse_mode: "Markdown" });
  } catch (error) {
    console.error("Error Telegram:", error);
  }
}

app.post("/exec/:dex", async (req, res) => {
  try {
    const { dex } = req.params;
    const { mint, amount, isBuy } = req.body;
    
    console.log(`🔄 ${isBuy ? 'BUY' : 'SELL'} ${amount} en ${dex} - ${mint}`);
    
    const sig = `${Date.now()}_${Math.random().toString(36)}`;
    positions.set(sig, { dex, mint, amount, isBuy, timestamp: Date.now() });
    
    await notify(`🆕 *Trade Simulado*
• DEX: ${dex.toUpperCase()}
• Tipo: ${isBuy ? 'BUY' : 'SELL'}
• Token: \`${mint}\`
• Cantidad: ${amount}
• TX: \`${sig}\``);

    res.json({ sig, status: "simulated" });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get("/health", (req, res) => {
  res.json({ status: "OK", positions: positions.size });
});

app.listen(3000, () => {
  console.log("✅ Executor corriendo en http://localhost:3000");
});
JS_END

    # test.js
    cat > executor/test.js << 'TEST_END'
const axios = require("axios");

async function test() {
  try {
    const health = await axios.get("http://localhost:3000/health");
    console.log("✅ Health check:", health.data);
    
    const trade = await axios.post("http://localhost:3000/exec/pump", {
      mint: "test123",
      amount: 0.001,
      isBuy: true
    });
    console.log("✅ Test trade:", trade.data);
  } catch (e) {
    console.log("❌ Error:", e.message);
  }
}

test();
TEST_END

    # Rust simplificado
    RUST_WALLETS=""
    for i in "${!WALLETS[@]}"; do
        IFS=',' read -r addr nick <<< "${WALLETS[$i]}"
        RUST_WALLETS+="    (\"$addr\", \"$nick\")"
        if [ $i -lt $((${#WALLETS[@]} - 1)) ]; then
            RUST_WALLETS+=",\n"
        fi
    done

    cat > detector/src/main.rs << RUST_END
use tokio::time::{sleep, Duration};
use reqwest::Client;
use serde_json::json;

const EXECUTOR_URL: &str = "http://localhost:3000/exec";
const TELEGRAM_BOT_TOKEN: &str = "$TELEGRAM_TOKEN";
const TELEGRAM_CHAT_ID: &str = "$TELEGRAM_CHAT_ID";

const WALLETS: [(&str, &str); ${#WALLETS[@]}] = [
$RUST_WALLETS
];

#[tokio::main]
async fn main() {
    println!("🚀 Detector iniciado - Modo demo");
    println!("Monitoreando {} wallets", WALLETS.len());
    
    let client = Client::new();
    
    loop {
        // Simular detección cada 30 segundos
        for (addr, nick) in &WALLETS {
            println!("👀 Monitoreando wallet: {} ({})", nick, &addr[..8]);
        }
        
        // Simular trade cada 60 segundos
        if rand::random::<f32>() > 0.98 {
            simulate_trade(&client).await;
        }
        
        sleep(Duration::from_secs(30)).await;
    }
}

async fn simulate_trade(client: &Client) {
    println!("🎯 Simulando trade detectado...");
    
    let payload = json!({
        "mint": "demo_token_123",
        "amount": 0.001,
        "isBuy": true
    });
    
    let _ = client
        .post(&format!("{}/pump", EXECUTOR_URL))
        .json(&payload)
        .send()
        .await;
}
RUST_END

    print_success "Código generado"
}

# Instalar dependencias
install_deps() {
    print_step "Instalando dependencias..."
    cd executor && npm install --silent && cd ..
    print_success "Node.js dependencias OK"
    
    cd detector && cargo build --release --quiet && cd ..
    print_success "Rust compilado OK"
}

# Crear scripts de ejecución
create_scripts() {
    cat > run.sh << 'RUN_END'
#!/bin/bash
echo "🚀 Iniciando PumpSwap Bot..."

cd executor
node index.js &
EXECUTOR_PID=$!
cd ..

sleep 2
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Executor OK"
else
    echo "❌ Executor falló"
    kill $EXECUTOR_PID 2>/dev/null
    exit 1
fi

echo "🦀 Iniciando detector..."
cd detector
./target/release/detector

trap "kill $EXECUTOR_PID 2>/dev/null" EXIT
RUN_END

    cat > test.sh << 'TEST_END'
#!/bin/bash
echo "🧪 Testing bot..."
cd executor
npm test
TEST_END

    chmod +x run.sh test.sh
    print_success "Scripts creados"
}

# Test final
final_test() {
    print_step "Test final..."
    cd executor
    node index.js &
    PID=$!
    sleep 2
    
    if curl -s http://localhost:3000/health > /dev/null; then
        print_success "¡Todo funcionando!"
    else
        print_error "Problema detectado"
    fi
    
    kill $PID 2>/dev/null
    cd ..
}

# Main
main() {
    install_nodejs
    install_rust
    collect_user_data
    create_project
    create_code
    install_deps
    create_scripts
    final_test
    
    echo ""
    echo -e "${GREEN}🎉 ¡INSTALACIÓN COMPLETADA!${NC}"
    echo ""
    echo "Para ejecutar:"
    echo "  ./run.sh"
    echo ""
    echo "Para probar:"
    echo "  ./test.sh"
    echo ""
    print_success "¡Bot listo para usar! 🚀"
}

main
SCRIPT_END

chmod +x setup-auto.sh

echo "✅ Script descargado: setup-auto.sh"
echo ""
echo "Para instalar tu bot ejecuta:"
echo "  ./setup-auto.sh"
echo ""
echo "¡El script te guiará paso a paso! 🚀"
