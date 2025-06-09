#!/bin/bash

# 🚀 PUMPSWAP TRADING BOT - INSTALADOR COMPLETO MEJORADO
# Versión que funciona correctamente con input del usuario

set -e

# Colores para output bonito
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

# Banner
echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║     🤖 PumpSwap Trading Bot - MEGA INSTALLER 🚀      ║
║                                                      ║
║     Este script contiene TODO el código incluido    ║
║     Solo ejecuta y responde las preguntas ⚡        ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar que estamos ejecutando el archivo directamente
if [ "$0" = "bash" ]; then
    print_error "No ejecutes este script con 'curl | bash'"
    echo "Usa en su lugar:"
    echo "curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/install.sh | bash"
    exit 1
fi

# Detectar OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
else
    OS="windows"
fi
print_success "Sistema: $OS"

# Verificar dependencias del sistema
check_system_deps() {
    print_step "Verificando dependencias del sistema..."
    
    if [[ "$OS" == "linux" ]]; then
        if ! command -v curl &> /dev/null; then
            print_error "curl no está instalado. Instálalo con: sudo apt-get install curl"
            exit 1
        fi
        if ! command -v sudo &> /dev/null; then
            print_error "sudo no está disponible"
            exit 1
        fi
    fi
    print_success "Dependencias del sistema OK"
}

# Instalar Node.js
install_nodejs() {
    print_step "Verificando Node.js..."
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            print_success "Node.js OK ($(node --version))"
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
        print_success "Rust OK ($(cargo --version))"
        return
    fi
    
    print_step "Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
    print_success "Rust instalado: $(cargo --version)"
}

# Función para input seguro
safe_read() {
    local prompt="$1"
    local var_name="$2"
    local example="$3"
    
    echo ""
    echo -e "${YELLOW}$prompt${NC}"
    if [ -n "$example" ]; then
        echo -e "${BLUE}Ejemplo: $example${NC}"
    fi
    echo -n "> "
    read -r input
    eval "$var_name='$input'"
}

# Recopilar configuración del usuario
collect_config() {
    print_step "Configuración personalizada..."
    echo ""
    echo -e "${PURPLE}Vamos a configurar tu bot paso a paso...${NC}"
    
    # Wallet privada
    safe_read "🔑 Tu wallet privada (array JSON):" "PAYER_SECRET" "[81,144,223,80,201,5,14,64...]"
    
    # Telegram
    safe_read "📱 Bot Token de Telegram:" "TELEGRAM_TOKEN" "123456:ABC-DEF..."
    safe_read "📱 Tu Chat ID de Telegram:" "TELEGRAM_CHAT_ID" "123456789"
    
    # APIs
    safe_read "🔧 Shyft API Key:" "SHYFT_API_KEY" "abc123..."
    
    echo ""
    echo -e "${YELLOW}🌐 API de Helius (opcional):${NC}"
    echo -e "${BLUE}Presiona ENTER para usar la de ejemplo${NC}"
    echo -n "> "
    read -r HELIUS_INPUT
    if [ -z "$HELIUS_INPUT" ]; then
        HELIUS_API_KEY="3724fd61-91e7-4863-a1a5-53507e3a122f"
        echo "Usando API de ejemplo"
    else
        HELIUS_API_KEY="$HELIUS_INPUT"
    fi
    
    # Wallets a seguir
    echo ""
    echo -e "${YELLOW}👥 Wallets a seguir:${NC}"
    echo -e "${BLUE}Formato: direccion,nickname${NC}"
    echo -e "${BLUE}Presiona ENTER sin escribir nada para terminar${NC}"
    
    WALLETS=()
    for i in {1..5}; do
        echo -n "Wallet $i > "
        read -r wallet_input
        if [ -z "$wallet_input" ]; then
            break
        fi
        WALLETS+=("$wallet_input")
    done
    
    if [ ${#WALLETS[@]} -eq 0 ]; then
        print_warning "Usando wallets de ejemplo"
        WALLETS=(
            "DfMxre4cKmvogbLrPigxmibVTTQDuzjdXojWzjCXXhzj,monstruo_pump"
            "EHg5YkU2SZBTvuT87rUsvxArGp3HLeye1fXaSDfuMyaf,gordo_data"
        )
    fi
    
    print_success "Configuración guardada"
}

# Crear estructura del proyecto
create_structure() {
    print_step "Creando estructura del proyecto..."
    rm -rf pumpswap-bot 2>/dev/null || true
    mkdir -p pumpswap-bot/{detector/src,executor}
    cd pumpswap-bot
    print_success "Estructura creada"
}

# Crear archivo .env
create_env() {
    print_step "Generando configuración (.env)..."
    cat > executor/.env << EOF
# Configuración de Wallet y RPC
PAYER_SECRET=$PAYER_SECRET
RPC_URL=https://api.mainnet-beta.solana.com

# Configuración de Telegram
TELEGRAM_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID

# Configuración de Trading
TAKE_PROFIT_PCT=0.40
STOP_LOSS_PCT=0.10
CHECK_INTERVAL_MS=15000

# API Keys
SHYFT_API_KEY=$SHYFT_API_KEY
HELIUS_API_KEY=$HELIUS_API_KEY
EOF
    print_success "Archivo .env creado"
}

# Crear package.json
create_package_json() {
    print_step "Creando package.json..."
    cat > executor/package.json << 'EOF'
{
  "name": "pumpswap-trading-bot",
  "version": "1.0.0",
  "description": "Bot de trading automatizado para PumpSwap y Raydium",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "node testTrade.js",
    "dev": "nodemon index.js"
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
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF
    print_success "package.json creado"
}

# Crear Cargo.toml
create_cargo_toml() {
    print_step "Creando Cargo.toml..."
    cat > detector/Cargo.toml << 'EOF'
[package]
name = "pumpswap-detector"
version = "0.2.0"
edition = "2021"
description = "Detector de swaps en tiempo real para PumpSwap y Raydium"

[dependencies]
tokio = { version = "1.0", features = ["full"] }
tokio-tungstenite = "0.21"
futures = "0.3"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
reqwest = { version = "0.11", features = ["json"] }
anyhow = "1.0"

[profile.release]
opt-level = 3
lto = true
EOF
    print_success "Cargo.toml creado"
}

# Crear index.js (CÓDIGO COMPLETO SIMPLIFICADO)
create_index_js() {
    print_step "Generando index.js..."
    cat > executor/index.js << 'EOF'
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const { Keypair, Connection } = require("@solana/web3.js");
const TelegramBot = require("node-telegram-bot-api");
const { gql, GraphQLClient } = require("graphql-request");

const {
  PAYER_SECRET, RPC_URL,
  TELEGRAM_TOKEN, TELEGRAM_CHAT_ID,
  TAKE_PROFIT_PCT, STOP_LOSS_PCT, CHECK_INTERVAL_MS,
  SHYFT_API_KEY
} = process.env;

if (!PAYER_SECRET || !RPC_URL || !TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID || !SHYFT_API_KEY) {
  console.error("❌ Faltan variables en .env");
  console.log("Verifica que todas las variables estén configuradas correctamente");
  process.exit(1);
}

const payer = Keypair.fromSecretKey(Uint8Array.from(JSON.parse(PAYER_SECRET)));
const connection = new Connection(RPC_URL, "confirmed");

// Configurar GraphQL client para Shyft
const graphQLClient = new GraphQLClient(
  `https://programs.shyft.to/v0/graphql/?api_key=${SHYFT_API_KEY}&network=mainnet-beta`,
  {
    method: 'POST',
    jsonSerializer: {
      parse: JSON.parse,
      stringify: JSON.stringify,
    },
  }
);

const bot = new TelegramBot(TELEGRAM_TOKEN);
const app = express();
app.use(bodyParser.json());

const positions = new Map();

async function notify(text) {
  try {
    await bot.sendMessage(TELEGRAM_CHAT_ID, text, { parse_mode: "Markdown" });
    console.log("📱 Notificación enviada");
  } catch (error) {
    console.error("❌ Error enviando mensaje Telegram:", error.message);
  }
}

// Función para obtener pool de PumpSwap usando Shyft
async function getPumpSwapPool(tokenMint) {
  const query = gql`
    query GetPumpSwapPool($tokenMint: String!) {
      pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA_Pool(
        where: {
          _or: [
            { baseMint: { _eq: $tokenMint } },
            { quoteMint: { _eq: $tokenMint } }
          ]
        }
      ) {
        pubkey
        baseMint
        quoteMint
        _updatedAt
      }
    }
  `;

  try {
    const result = await graphQLClient.request(query, { tokenMint });
    return result.pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA_Pool[0];
  } catch (error) {
    console.error("Error fetching PumpSwap pool:", error.message);
    return null;
  }
}

// Función para simular precio (versión demo)
async function getPrice(dex, tokenMint, amount, isBuy) {
  if (dex === "pump") {
    try {
      const pool = await getPumpSwapPool(tokenMint);
      if (!pool) {
        console.log(`⚠️  Pool no encontrado para ${tokenMint}, usando precio simulado`);
      }
      return Math.random() * 0.000001 + 0.0000001;
    } catch (error) {
      console.error("Error getting price:", error.message);
      return Math.random() * 0.000001 + 0.0000001;
    }
  } else {
    return Math.random() * 0.000001 + 0.0000001;
  }
}

// Función para simular trade (MODO DEMO)
async function executeTrade(dex, tokenMint, amount, isBuy) {
  console.log(`🔄 [SIMULACIÓN] ${isBuy ? 'BUY' : 'SELL'} de ${amount} en ${dex} para ${tokenMint.substring(0, 8)}...`);
  
  // Simular delay de network
  await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
  
  // Generar signature simulada
  const fakeSignature = `sim_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  console.log(`✅ Trade simulado completado: ${fakeSignature}`);
  return fakeSignature;
}

// Monitor de posiciones (simplificado)
setInterval(async () => {
  if (positions.size === 0) return;
  
  console.log(`📊 Monitoreando ${positions.size} posiciones...`);
  
  for (let [id, pos] of positions) {
    try {
      // Simular cambio de precio
      const currentPrice = pos.entryPrice * (0.9 + Math.random() * 0.2);
      
      const pnl = pos.isBuy
        ? (currentPrice - pos.entryPrice) / pos.entryPrice
        : (pos.entryPrice - currentPrice) / pos.entryPrice;

      // Check exit conditions
      const takeProfit = parseFloat(TAKE_PROFIT_PCT);
      const stopLoss = parseFloat(STOP_LOSS_PCT);
      
      if (pnl >= takeProfit || pnl <= -stopLoss) {
        const exitType = pnl >= takeProfit ? "TAKE_PROFIT" : "STOP_LOSS";
        
        await notify(`⚡ *${exitType}* ${pos.dex.toUpperCase()}
• Token: \`${pos.mint.substring(0, 8)}...\`
• PnL: ${(pnl * 100).toFixed(2)}%
• TX: \`${id}\``);
        
        positions.delete(id);
        console.log(`🎯 ${exitType} ejecutado para ${pos.mint.substring(0, 8)}... (${(pnl * 100).toFixed(2)}%)`);
      }
    } catch (err) {
      console.error("Error checking position", id, err.message);
    }
  }
}, parseInt(CHECK_INTERVAL_MS) || 15000);

// Endpoint para ejecutar trades
app.post("/exec/:dex", async (req, res) => {
  try {
    const dex = req.params.dex;
    const { mint, amount, isBuy } = req.body;
    
    if (!mint || !amount || typeof isBuy !== 'boolean') {
      return res.status(400).json({ error: "Parámetros inválidos" });
    }

    console.log(`📋 Ejecutando ${isBuy ? 'BUY' : 'SELL'} de ${amount} para ${mint.substring(0, 8)}... en ${dex}`);
    
    const sig = await executeTrade(dex, mint, amount, isBuy);
    const entryPrice = await getPrice(dex, mint, amount, isBuy);

    positions.set(sig, { 
      dex, 
      mint, 
      amount, 
      isBuy, 
      entryPrice, 
      timestamp: Date.now() 
    });

    await notify(`🆕 *Entry [DEMO]* ${dex.toUpperCase()} ${isBuy ? "BUY" : "SELL"}
• Token: \`${mint.substring(0, 8)}...\`
• Cantidad: ${amount}
• Precio: ${entryPrice.toFixed(8)}
• TX: \`${sig}\``);

    res.json({ sig, entryPrice, status: "simulated", message: "Trade simulado exitosamente" });
  } catch (e) {
    console.error("Error in trade execution:", e.message);
    res.status(500).json({ error: e.message });
  }
});

app.get("/positions", (req, res) => {
  const positionsArray = Array.from(positions.entries()).map(([id, pos]) => ({
    id,
    ...pos,
    age: Date.now() - pos.timestamp
  }));
  res.json({
    count: positionsArray.length,
    positions: positionsArray
  });
});

app.get("/health", (req, res) => {
  res.json({ 
    status: "OK", 
    mode: "SIMULATION",
    positions: positions.size,
    timestamp: new Date().toISOString(),
    wallet: payer.publicKey.toString(),
    uptime: process.uptime()
  });
});

const PORT = process.env.PORT || 3000;

// Test inicial
async function testSetup() {
  try {
    // Test Telegram
    console.log("🧪 Testeando Telegram...");
    await notify("🤖 *Bot iniciado correctamente*\n\n⚠️ _Modo simulación activo_");
    
    // Test Shyft
    console.log("🧪 Testeando Shyft API...");
    const testQuery = gql`query { __type(name: "Query") { name } }`;
    await graphQLClient.request(testQuery);
    
    console.log("✅ Todos los tests pasaron");
  } catch (error) {
    console.warn("⚠️  Algunos tests fallaron:", error.message);
    console.log("El bot funcionará pero verifica tu configuración");
  }
}

app.listen(PORT, async () => {
  console.log("🚀 ===============================================");
  console.log(`✅ Executor corriendo en http://localhost:${PORT}`);
  console.log(`📊 Monitoreando ${positions.size} posiciones`);
  console.log(`🤖 Bot de Telegram configurado`);
  console.log(`⚠️  MODO SIMULACIÓN - Los trades son ficticios`);
  console.log(`👤 Wallet: ${payer.publicKey.toString()}`);
  console.log("🚀 ===============================================");
  
  await testSetup();
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});
EOF
    print_success "index.js creado"
}

# Crear testTrade.js (simplificado)
create_test_trade() {
    print_step "Generando testTrade.js..."
    cat > executor/testTrade.js << 'EOF'
const axios = require("axios");

async function testBot() {
  console.log("🧪 Testing PumpSwap Trading Bot");
  console.log("===============================");
  
  try {
    // Test 1: Health check
    console.log("\n1️⃣ Testing health endpoint...");
    const healthResponse = await axios.get("http://localhost:3000/health");
    console.log("✅ Health OK:", healthResponse.data);
    
    // Test 2: Positions
    console.log("\n2️⃣ Testing positions endpoint...");
    const positionsResponse = await axios.get("http://localhost:3000/positions");
    console.log("✅ Positions OK:", positionsResponse.data);
    
    // Test 3: Demo trade
    console.log("\n3️⃣ Testing demo trade...");
    const tradeResponse = await axios.post("http://localhost:3000/exec/pump", {
      mint: "5B1o489Hm8rBgrebAtxfY8Sjma6j9EfFhZXpPyjCpump",
      amount: 0.001,
      isBuy: true
    });
    console.log("✅ Demo trade OK:", tradeResponse.data);
    
    console.log("\n🎉 ¡Todos los tests pasaron!");
    console.log("Tu bot está funcionando correctamente.");
    
  } catch (error) {
    console.error("\n❌ Test falló:", error.response?.data || error.message);
    console.log("\n💡 Asegúrate de que el servidor esté corriendo:");
    console.log("   npm start");
  }
}

testBot();
EOF
    print_success "testTrade.js creado"
}

# Crear main.rs (versión simplificada)
create_main_rs() {
    print_step "Generando detector Rust..."
    
    # Generar array de wallets para Rust
    RUST_WALLETS=""
    for i in "${!WALLETS[@]}"; do
        IFS=',' read -r addr nick <<< "${WALLETS[$i]}"
        RUST_WALLETS+="    (\"$addr\", \"$nick\")"
        if [ $i -lt $((${#WALLETS[@]} - 1)) ]; then
            RUST_WALLETS+=",\n"
        fi
    done
    
    cat > detector/src/main.rs << EOF
use tokio::time::{sleep, Duration};
use reqwest::Client;
use serde_json::json;
use anyhow::Result;

const EXECUTOR_URL: &str = "http://localhost:3000/exec";
const TELEGRAM_BOT_TOKEN: &str = "$TELEGRAM_TOKEN";
const TELEGRAM_CHAT_ID: &str = "$TELEGRAM_CHAT_ID";

const WALLETS: [(&str, &str); ${#WALLETS[@]}] = [
$RUST_WALLETS
];

#[tokio::main]
async fn main() -> Result<()> {
    println!("🚀 Detector PumpSwap iniciado (Modo Demo)");
    println!("Monitoreando {} wallets:", WALLETS.len());
    
    for (addr, nick) in &WALLETS {
        println!("  👤 {} ({}...{})", nick, &addr[..8], &addr[addr.len()-8..]);
    }
    println!("");
    
    let client = Client::new();
    
    // Notificar inicio
    let _ = notify_telegram(&client, "🦀 *Detector iniciado*\n\n👀 Monitoreando wallets en modo demo...").await;
    
    loop {
        // Demo: simular detección cada 60 segundos
        println!("👀 Monitoreando wallets...");
        
        // Simular detección ocasional
        if rand::random::<f32>() > 0.95 {
            simulate_swap_detection(&client).await;
        }
        
        sleep(Duration::from_secs(30)).await;
    }
}

async fn simulate_swap_detection(client: &Client) {
    let wallet = &WALLETS[0]; // Usar primera wallet para demo
    let demo_token = "5B1o489Hm8rBgrebAtxfY8Sjma6j9EfFhZXpPyjCpump";
    
    println!("🎯 [DEMO] Swap simulado detectado: {} en PumpSwap", wallet.1);
    
    // Simular llamada al executor
    let payload = json!({
        "mint": demo_token,
        "amount": 0.001,
        "isBuy": true
    });
    
    match client
        .post(&format!("{}/pump", EXECUTOR_URL))
        .json(&payload)
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => {
            println!("✅ Demo trade enviado al executor");
        }
        Ok(resp) => {
            println!("⚠️  Executor respondió: {}", resp.status());
        }
        Err(e) => {
            println!("❌ Error conectando al executor: {}", e);
        }
    }
    
    let _ = notify_telegram(
        client,
        &format!(
            "🎯 *Swap Demo Detectado*\n\n👤 **Trader:** {}\n🏪 **DEX:** PumpSwap\n📊 **Acción:** COMPRA\n\n_Trade demo enviado al executor..._",
            wallet.1
        )
    ).await;
}

async fn notify_telegram(client: &Client, text: &str) -> Result<()> {
    let url = format!("https://api.telegram.org/bot{}/sendMessage", TELEGRAM_BOT_TOKEN);
    
    let _ = client
        .post(&url)
        .json(&json!({
            "chat_id": TELEGRAM_CHAT_ID,
            "text": text,
            "parse_mode": "Markdown"
        }))
        .send()
        .await?;
    
    Ok(())
}

// Generar números aleatorios simple
mod rand {
    use std::time::{SystemTime, UNIX_EPOCH};
    
    pub fn random<T>() -> T
    where
        T: From<f32>,
    {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap();
        let seed = now.as_nanos() as u64;
        let value = ((seed.wrapping_mul(1103515245).wrapping_add(12345)) >> 16) as f32 / 32768.0;
        T::from(value)
    }
}
EOF
    print_success "main.rs creado"
}

# Instalar dependencias Node.js
install_node_deps() {
    print_step "Instalando dependencias Node.js..."
    cd executor
    npm install --silent --no-progress 2>/dev/null || npm install
    cd ..
    print_success "Dependencias Node.js instaladas"
}

# Compilar Rust
compile_rust() {
    print_step "Compilando detector Rust..."
    cd detector
    # Asegurar que cargo esté en PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    cargo build --release --quiet 2>/dev/null || cargo build --release
    cd ..
    print_success "Detector Rust compilado"
}

# Crear scripts de ejecución
create_scripts() {
    print_step "Creando scripts de ejecución..."
    
    cat > run.sh << 'EOF'
#!/bin/bash

echo "🚀 Iniciando PumpSwap Trading Bot"
echo "================================"

# Verificar archivo .env
if [ ! -f executor/.env ]; then
    echo "❌ Archivo .env no encontrado en executor/"
    exit 1
fi

# Función para limpiar procesos al salir
cleanup() {
    echo "🧹 Limpiando procesos..."
    kill $EXECUTOR_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM

# Iniciar executor en background
echo "📡 Iniciando executor Node.js..."
cd executor
node index.js &
EXECUTOR_PID=$!
cd ..

# Esperar a que el executor esté listo
echo "⏳ Esperando executor..."
for i in {1..10}; do
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "❌ Executor no está respondiendo después de 10 segundos"
    kill $EXECUTOR_PID 2>/dev/null
    exit 1
fi

echo "✅ Executor funcionando en http://localhost:3000"
echo "📊 Puedes ver el estado en: http://localhost:3000/health"
echo ""

# Iniciar detector Rust
echo "🦀 Iniciando detector Rust..."
cd detector
export PATH="$HOME/.cargo/bin:$PATH"
./target/release/pumpswap-detector

# El script termina aquí cuando se detiene el detector
cleanup
EOF

    cat > test.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing PumpSwap Trading Bot"
echo "==============================="

# Verificar si el servidor está corriendo
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "❌ Servidor no está corriendo"
    echo "Inicia el bot primero con: ./run.sh"
    exit 1
fi

cd executor
echo "🚀 Ejecutando tests..."
npm test

echo ""
echo "✅ Tests completados"
echo "💡 Para ver más detalles:"
echo "  curl http://localhost:3000/health"
echo "  curl http://localhost:3000/positions"
EOF

    chmod +x run.sh test.sh
    print_success "Scripts de ejecución creados"
}

# Test final
final_test() {
    print_step "Ejecutando test final..."
    
    # Test rápido del executor
    cd executor
    echo "Iniciando test del executor..."
    timeout 10s node index.js > test.log 2>&1 &
    TEST_PID=$!
    sleep 3
    
    if kill -0 $TEST_PID 2>/dev/null; then
        print_success "Executor test OK"
        kill $TEST_PID 2>/dev/null
    else
        print_warning "Test incompleto - revisa la configuración"
        echo "Log del test:"
        cat test.log
    fi
    
    rm -f test.log
    cd ..
}

# Crear README
create_readme() {
    print_step "Creando documentación..."
    cat > README.md << 'EOF'
# 🤖 PumpSwap Trading Bot

Bot de copy trading automático para PumpSwap y Raydium en Solana.

## 🚀 Instalación Automática

```bash
curl -sSL https://raw.githubusercontent.com/cadmusreal02/pumpswap-trading-bot/main/install.sh | bash
```

## 📋 Uso Rápido

### 1. Ejecutar el bot completo:
```bash
cd pumpswap-bot
./run.sh
```

### 2. Probar en otra terminal:
```bash
cd pumpswap-bot
./test.sh
```

## 📊 Endpoints API

- `http://localhost:3000/health` - Estado del bot
- `http://localhost:3000/positions` - Posiciones activas

## ⚙️ Configuración

Todo está en `executor/.env`. Principales parámetros:

- `TAKE_PROFIT_PCT=0.40` - 40% ganancia para cerrar
- `STOP_LOSS_PCT=0.10` - 10% pérdida para cerrar

## 🎯 Modo Demo

El bot inicia en **MODO SIMULACIÓN** por seguridad:
- Todos los trades son ficticios
- Puedes probar sin riesgo
- Notificaciones reales por Telegram

## 🔧 Para Trading Real

Modifica las funciones en `executor/index.js`:
- `executeTrade()` - Cambiar por llamadas reales a SDKs
- `getPrice()` - Integrar precios reales

## ⚠️ Importante

- Empieza con cantidades pequeñas (0.001 SOL)
- Verifica todas las API keys
- Usa testnet primero

¡Happy trading! 🚀
EOF
    print_success "README.md creado"
}

# Mostrar resumen final
show_summary() {
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║         🎉 ¡INSTALACIÓN COMPLETADA! 🎉               ║
║                                                      ║
║    Tu bot de copy trading está 100% listo           ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}📁 Proyecto creado en:${NC} $(pwd)"
    echo ""
    echo -e "${YELLOW}🚀 Para ejecutar tu bot:${NC}"
    echo "  cd pumpswap-bot"
    echo "  ./run.sh"
    echo ""
    echo -e "${YELLOW}🧪 Para probar (en otra terminal):${NC}"
    echo "  cd pumpswap-bot"
    echo "  ./test.sh"
    echo ""
    echo -e "${YELLOW}📊 Ver estado del bot:${NC}"
    echo "  curl http://localhost:3000/health"
    echo ""
    echo -e "${PURPLE}⚠️  IMPORTANTE:${NC}"
    echo "• El bot inicia en MODO SIMULACIÓN"
    echo "• Todos los trades son ficticios hasta que los modifiques"
    echo "• Usa cantidades pequeñas para probar"
    echo ""
    echo -e "${GREEN}🎯 ¡Tu bot ya está listo!${NC}"
    echo ""
}

# EJECUCIÓN PRINCIPAL
main() {
    check_system_deps
    install_nodejs
    install_rust
    collect_config
    create_structure
    create_env
    create_package_json
    create_cargo_toml
    create_index_js
    create_test_trade
    create_main_rs
    install_node_deps
    compile_rust
    create_scripts
    create_readme
    final_test
    show_summary
}

# Ejecutar script principal
main
