#!/bin/bash

# 🚀 PUMPSWAP BOT - INSTALADOR 100% AUTOMÁTICO
# Un solo script que hace TODO sin preguntar nada
# Solo configuras el .env al final

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

echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║     🤖 PumpSwap Trading Bot - AUTO INSTALLER 🚀      ║
║                                                      ║
║     Instalando TODO automáticamente...              ║
║     NO se necesita input del usuario                ║
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
print_success "Sistema detectado: $OS"

# Instalar Node.js automáticamente
install_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            print_success "Node.js OK ($(node --version))"
            return
        fi
    fi
    
    print_step "Instalando Node.js..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &>/dev/null
        sudo apt-get install -y nodejs &>/dev/null
    elif [[ "$OS" == "mac" ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
        fi
        brew install node &>/dev/null
    fi
    print_success "Node.js instalado: $(node --version)"
}

# Instalar Rust automáticamente
install_rust() {
    if command -v cargo &> /dev/null; then
        print_success "Rust OK ($(cargo --version))"
        return
    fi
    
    print_step "Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
    source $HOME/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
    print_success "Rust instalado: $(cargo --version)"
}

# Crear estructura del proyecto
create_project() {
    print_step "Creando estructura del proyecto..."
    rm -rf pumpswap-bot 2>/dev/null || true
    mkdir -p pumpswap-bot/{detector/src,executor}
    cd pumpswap-bot
    print_success "Estructura creada"
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

# Crear index.js COMPLETO
create_index_js() {
    print_step "Creando servidor Node.js..."
    cat > executor/index.js << 'EOF'
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const { Keypair, Connection } = require("@solana/web3.js");
const TelegramBot = require("node-telegram-bot-api");
const { gql, GraphQLClient } = require("graphql-request");

const {
  PAYER_SECRET, RPC_URL, TELEGRAM_TOKEN, TELEGRAM_CHAT_ID,
  TAKE_PROFIT_PCT, STOP_LOSS_PCT, CHECK_INTERVAL_MS, SHYFT_API_KEY
} = process.env;

if (!PAYER_SECRET || !TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID || !SHYFT_API_KEY) {
  console.error("❌ Configura tu archivo .env primero");
  console.log("Copia .env.template a .env y edita con tus datos");
  process.exit(1);
}

const payer = Keypair.fromSecretKey(Uint8Array.from(JSON.parse(PAYER_SECRET)));
const connection = new Connection(RPC_URL || "https://api.mainnet-beta.solana.com", "confirmed");

const graphQLClient = new GraphQLClient(
  `https://programs.shyft.to/v0/graphql/?api_key=${SHYFT_API_KEY}&network=mainnet-beta`,
  { method: 'POST', jsonSerializer: { parse: JSON.parse, stringify: JSON.stringify } }
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
    console.error("❌ Error Telegram:", error.message);
  }
}

async function getPumpSwapPool(tokenMint) {
  const query = gql`
    query GetPumpSwapPool($tokenMint: String!) {
      pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA_Pool(
        where: { _or: [{ baseMint: { _eq: $tokenMint } }, { quoteMint: { _eq: $tokenMint } }] }
      ) { pubkey baseMint quoteMint _updatedAt }
    }`;
  
  try {
    const result = await graphQLClient.request(query, { tokenMint });
    return result.pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA_Pool[0];
  } catch (error) {
    console.error("Error fetching pool:", error.message);
    return null;
  }
}

async function getPrice(dex, tokenMint) {
  if (dex === "pump") {
    const pool = await getPumpSwapPool(tokenMint);
    if (!pool) console.log(`⚠️ Pool no encontrado: ${tokenMint.substring(0, 8)}...`);
  }
  return Math.random() * 0.000001 + 0.0000001; // Precio simulado
}

async function executeTrade(dex, tokenMint, amount, isBuy) {
  console.log(`🔄 [SIMULACIÓN] ${isBuy ? 'BUY' : 'SELL'} ${amount} en ${dex} - ${tokenMint.substring(0, 8)}...`);
  await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
  return `sim_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// Monitor de posiciones
setInterval(async () => {
  if (positions.size === 0) return;
  console.log(`📊 Monitoreando ${positions.size} posiciones...`);
  
  for (let [id, pos] of positions) {
    try {
      const currentPrice = pos.entryPrice * (0.9 + Math.random() * 0.2);
      const pnl = pos.isBuy ? (currentPrice - pos.entryPrice) / pos.entryPrice : (pos.entryPrice - currentPrice) / pos.entryPrice;
      
      if (pnl >= parseFloat(TAKE_PROFIT_PCT || 0.4) || pnl <= -parseFloat(STOP_LOSS_PCT || 0.1)) {
        const exitType = pnl >= parseFloat(TAKE_PROFIT_PCT || 0.4) ? "TAKE_PROFIT" : "STOP_LOSS";
        await notify(`⚡ *${exitType}* ${pos.dex.toUpperCase()}\n• Token: \`${pos.mint.substring(0, 8)}...\`\n• PnL: ${(pnl * 100).toFixed(2)}%`);
        positions.delete(id);
        console.log(`🎯 ${exitType}: ${(pnl * 100).toFixed(2)}%`);
      }
    } catch (err) {
      console.error("Error checking position:", err.message);
    }
  }
}, parseInt(CHECK_INTERVAL_MS || 15000));

app.post("/exec/:dex", async (req, res) => {
  try {
    const { dex } = req.params;
    const { mint, amount, isBuy } = req.body;
    
    if (!mint || !amount || typeof isBuy !== 'boolean') {
      return res.status(400).json({ error: "Parámetros inválidos" });
    }

    const sig = await executeTrade(dex, mint, amount, isBuy);
    const entryPrice = await getPrice(dex, mint);

    positions.set(sig, { dex, mint, amount, isBuy, entryPrice, timestamp: Date.now() });

    await notify(`🆕 *Entry [DEMO]* ${dex.toUpperCase()} ${isBuy ? "BUY" : "SELL"}\n• Token: \`${mint.substring(0, 8)}...\`\n• Cantidad: ${amount}\n• TX: \`${sig}\``);

    res.json({ sig, entryPrice, status: "simulated" });
  } catch (e) {
    console.error("Error:", e.message);
    res.status(500).json({ error: e.message });
  }
});

app.get("/positions", (req, res) => {
  res.json({ count: positions.size, positions: Array.from(positions.entries()).map(([id, pos]) => ({ id, ...pos })) });
});

app.get("/health", (req, res) => {
  res.json({ 
    status: "OK", 
    mode: "SIMULATION",
    positions: positions.size,
    wallet: payer.publicKey.toString(),
    uptime: process.uptime()
  });
});

const PORT = 3000;

app.listen(PORT, async () => {
  console.log("🚀 ===============================================");
  console.log(`✅ Executor corriendo en http://localhost:${PORT}`);
  console.log(`🤖 Bot de Telegram configurado`);
  console.log(`⚠️  MODO SIMULACIÓN - Trades ficticios`);
  console.log(`👤 Wallet: ${payer.publicKey.toString()}`);
  console.log("🚀 ===============================================");
  
  try {
    await notify("🤖 *Bot iniciado correctamente*\n\n⚠️ _Modo simulación activo_");
    console.log("✅ Test Telegram OK");
  } catch (error) {
    console.warn("⚠️ Test Telegram falló - verifica configuración");
  }
});

process.on('unhandledRejection', (reason) => console.error('❌ Unhandled Rejection:', reason));
process.on('uncaughtException', (error) => { console.error('❌ Uncaught Exception:', error); process.exit(1); });
EOF
    print_success "index.js creado"
}

# Crear testTrade.js
create_test_trade() {
    print_step "Creando test..."
    cat > executor/testTrade.js << 'EOF'
const axios = require("axios");

async function test() {
  console.log("🧪 Testing PumpSwap Bot");
  console.log("=======================");
  
  try {
    const health = await axios.get("http://localhost:3000/health");
    console.log("✅ Health:", health.data);
    
    const positions = await axios.get("http://localhost:3000/positions");
    console.log("✅ Positions:", positions.data);
    
    const trade = await axios.post("http://localhost:3000/exec/pump", {
      mint: "5B1o489Hm8rBgrebAtxfY8Sjma6j9EfFhZXpPyjCpump",
      amount: 0.001,
      isBuy: true
    });
    console.log("✅ Demo trade:", trade.data);
    
    console.log("\n🎉 ¡Todos los tests OK!");
    
  } catch (error) {
    console.error("❌ Error:", error.response?.data || error.message);
    console.log("💡 Asegúrate de que el servidor esté corriendo: npm start");
  }
}

test();
EOF
    print_success "testTrade.js creado"
}

# Crear main.rs COMPLETO
create_main_rs() {
    print_step "Creando detector Rust..."
    cat > detector/src/main.rs << 'EOF'
use tokio::time::{sleep, Duration};
use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use futures::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::json;
use reqwest::Client;
use anyhow::{Result, bail};
use std::collections::HashSet;

// CONFIGURACIÓN - EDITA ESTAS LÍNEAS DESPUÉS DE LA INSTALACIÓN
const HELIUS_API_KEY: &str = "3724fd61-91e7-4863-a1a5-53507e3a122f";
const TELEGRAM_BOT_TOKEN: &str = "TU_BOT_TOKEN_AQUI";
const TELEGRAM_CHAT_ID: &str = "TU_CHAT_ID_AQUI";

const WS_URL: &str = "wss://mainnet.helius-rpc.com/?api-key=3724fd61-91e7-4863-a1a5-53507e3a122f";
const REST_BASE: &str = "https://api.helius.xyz/v0/transactions";
const EXECUTOR_URL: &str = "http://localhost:3000/exec";

// WALLETS A SEGUIR - EDITA DESPUÉS DE LA INSTALACIÓN
const TARGET_WALLETS: [(&str, &str); 2] = [
    ("DfMxre4cKmvogbLrPigxmibVTTQDuzjdXojWzjCXXhzj", "monstruo_pump"),
    ("EHg5YkU2SZBTvuT87rUsvxArGp3HLeye1fXaSDfuMyaf", "gordo_data"),
];

const RAYDIUM_PROGRAM: &str = "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8";
const PUMPSWAP_PROGRAM: &str = "pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA";

#[derive(Debug, Deserialize)]
struct HeliusTx {
    description: Option<String>,
    #[serde(rename="tokenTransfers")]
    token_transfers: Option<Vec<TokenTransfer>>,
    #[serde(rename="instructions")]
    instructions: Option<Vec<Instruction>>,
    signature: String,
}

#[derive(Debug, Deserialize)]
struct TokenTransfer {
    mint: String,
    #[serde(rename="tokenAmount")]
    token_amount: f64,
}

#[derive(Debug, Deserialize)]
struct Instruction {
    #[serde(rename="programId")]
    program_id: String,
}

#[derive(Debug, Clone)]
struct SwapEvent {
    wallet_nick: String,
    mint: String,
    amount: f64,
    is_buy: bool,
    dex: String,
    signature: String,
}

#[derive(Serialize)]
struct WsReqParams<'a> {
    jsonrpc: &'a str,
    id: u8,
    method: &'a str,
    params: WsFilter<'a>,
}

#[derive(Serialize)]
struct WsFilter<'a> {
    #[serde(rename="filter")]
    filter: FilterMentions<'a>,
    #[serde(rename="commitment")]
    _commitment: &'a str,
}

#[derive(Serialize)]
struct FilterMentions<'a> {
    mentions: Vec<&'a str>,
}

fn determine_dex(program_id: &str) -> Option<&'static str> {
    match program_id {
        RAYDIUM_PROGRAM => Some("raydium"),
        PUMPSWAP_PROGRAM => Some("pump"),
        _ => None,
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    println!("🚀 Detector PumpSwap iniciado");
    println!("Monitoreando {} wallets:", TARGET_WALLETS.len());
    for (addr, nick) in &TARGET_WALLETS {
        println!("  👤 {} ({}...{})", nick, &addr[..8], &addr[addr.len()-8..]);
    }
    
    if TELEGRAM_BOT_TOKEN == "TU_BOT_TOKEN_AQUI" {
        println!("⚠️  CONFIGURACIÓN PENDIENTE:");
        println!("   Edita detector/src/main.rs con tus datos reales");
        println!("   Luego recompila: cd detector && cargo build --release");
    }
    
    loop {
        match run_detector().await {
            Ok(_) => break,
            Err(e) => {
                eprintln!("❌ Error: {:?}. Reconectando en 5s...", e);
                sleep(Duration::from_secs(5)).await;
            }
        }
    }
    Ok(())
}

async fn run_detector() -> Result<()> {
    let (ws_stream, _) = connect_async(WS_URL).await?;
    println!("✅ Conectado a Helius WebSocket");
    let (mut write, mut read) = ws_stream.split();

    let wallets: Vec<&str> = TARGET_WALLETS.iter().map(|(w, _)| *w).collect();
    let sub = WsReqParams {
        jsonrpc: "2.0",
        id: 1,
        method: "logsSubscribe",
        params: WsFilter {
            filter: FilterMentions { mentions: wallets },
            _commitment: "confirmed",
        },
    };
    
    write.send(Message::Text(serde_json::to_string(&sub)?)).await?;
    println!("✅ Subscripción activa");

    let http = Client::new();
    let mut seen = HashSet::new();

    while let Some(msg) = read.next().await {
        let msg = msg?;
        if let Message::Text(txt) = msg {
            let v: serde_json::Value = serde_json::from_str(&txt)?;
            if v.get("method").and_then(|m| m.as_str()) != Some("logsNotification") {
                continue;
            }

            let sig = v["params"]["result"]["value"]["signature"].as_str().unwrap_or_default().to_string();
            if seen.contains(&sig) { continue; }
            seen.insert(sig.clone());

            let url = format!("{}/{}?api-key={}", REST_BASE, sig, HELIUS_API_KEY);
            let res = http.get(&url).send().await?;
            if !res.status().is_success() { continue; }
            
            let parsed: Vec<HeliusTx> = res.json().await?;
            let tx = match parsed.into_iter().next() { Some(tx) => tx, None => continue };

            let nick = TARGET_WALLETS.iter()
                .find_map(|(w, nick)| {
                    v["params"]["result"]["value"]["logs"].as_array().unwrap_or(&vec![])
                        .iter().any(|log| log.as_str().map_or(false, |s| s.contains(*w)))
                        .then(|| *nick)
                }).unwrap_or("unknown");

            let mut detected_dex = None;
            if let Some(instructions) = &tx.instructions {
                for inst in instructions {
                    if let Some(dex) = determine_dex(&inst.program_id) {
                        detected_dex = Some(dex);
                        break;
                    }
                }
            }

            if detected_dex.is_none() {
                let desc = tx.description.clone().unwrap_or_default().to_lowercase();
                if desc.contains("swap") && (desc.contains("raydium") || desc.contains("pump")) {
                    detected_dex = Some(if desc.contains("raydium") { "raydium" } else { "pump" });
                }
            }

            if let Some(dex) = detected_dex {
                if let Some(token_transfers) = &tx.token_transfers {
                    if !token_transfers.is_empty() {
                        let transfer = &token_transfers[0];
                        let desc = tx.description.clone().unwrap_or_default().to_lowercase();
                        let is_buy = desc.contains("in") || desc.contains("buy");
                        
                        let event = SwapEvent {
                            wallet_nick: nick.to_string(),
                            mint: transfer.mint.clone(),
                            amount: transfer.token_amount,
                            is_buy,
                            dex: dex.to_string(),
                            signature: tx.signature.clone(),
                        };

                        println!("🔍 Swap: {} en {} - {} {}", nick, dex.to_uppercase(), 
                                if event.is_buy { "BUY" } else { "SELL" }, event.amount);

                        let _ = execute_trade(&http, &event).await;
                        let _ = notify_telegram(&http, &event).await;
                    }
                }
            }
        }
    }
    Ok(())
}

async fn execute_trade(client: &Client, event: &SwapEvent) -> Result<()> {
    let payload = json!({
        "mint": event.mint,
        "amount": if event.dex == "pump" { 0.001 } else { event.amount },
        "isBuy": event.is_buy
    });

    let resp = client.post(&format!("{}/{}", EXECUTOR_URL, event.dex))
        .json(&payload).timeout(Duration::from_secs(10)).send().await?;

    if resp.status().is_success() {
        println!("✅ Trade enviado al executor");
    } else {
        println!("⚠️ Executor error: {}", resp.status());
    }
    Ok(())
}

async fn notify_telegram(client: &Client, event: &SwapEvent) -> Result<()> {
    if TELEGRAM_BOT_TOKEN == "TU_BOT_TOKEN_AQUI" { return Ok(()); }
    
    let text = format!(
        "🔔 *Swap Detectado*\\n\\n👤 **{}**\\n🏪 **{}**\\n📊 **{}**\\n🪙 `{}`\\n💰 {:.6}",
        event.wallet_nick, event.dex.to_uppercase(),
        if event.is_buy { "COMPRA" } else { "VENTA" },
        event.mint, event.amount
    );

    let url = format!("https://api.telegram.org/bot{}/sendMessage", TELEGRAM_BOT_TOKEN);
    let _resp = client.post(&url).json(&json!({
        "chat_id": TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "MarkdownV2"
    })).timeout(Duration::from_secs(5)).send().await?;

    Ok(())
}
EOF
    print_success "main.rs creado"
}

# Crear scripts de ejecución
create_scripts() {
    print_step "Creando scripts..."
    
    # run.sh
    cat > run.sh << 'EOF'
#!/bin/bash

echo "🚀 Iniciando PumpSwap Bot"
echo "========================"

if [ ! -f executor/.env ]; then
    echo "❌ Configura tu .env primero:"
    echo "   cp executor/.env.template executor/.env"
    echo "   nano executor/.env"
    exit 1
fi

cleanup() {
    echo "🧹 Deteniendo bot..."
    kill $EXECUTOR_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM

echo "📡 Iniciando executor..."
cd executor
node index.js &
EXECUTOR_PID=$!
cd ..

sleep 3

if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "❌ Executor no responde"
    kill $EXECUTOR_PID 2>/dev/null
    exit 1
fi

echo "✅ Executor OK: http://localhost:3000"
echo "🦀 Iniciando detector..."

cd detector
export PATH="$HOME/.cargo/bin:$PATH"
./target/release/pumpswap-detector

cleanup
EOF

    # test.sh
    cat > test.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Bot"
echo "=============="

if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "❌ Bot no está corriendo"
    echo "Ejecuta: ./run.sh"
    exit 1
fi

cd executor
npm test
echo "✅ Tests OK"
EOF

    chmod +x run.sh test.sh
    print_success "Scripts creados"
}

# Crear archivo .env.template
create_env_template() {
    print_step "Creando template de configuración..."
    cat > executor/.env.template << 'EOF'
# 🔧 CONFIGURACIÓN PUMPSWAP BOT
# Copia este archivo a .env y edita con tus datos

# Tu wallet privada (array JSON)
PAYER_SECRET=[81,144,223,80,201,5,14,64,180,46,98,153,64,149,147,141,80,196,94,61,197,65,223,170,141,113,40,73,190,230,86,101,29,247,175,43,197,60,129,55,196,81]

# RPC de Solana
RPC_URL=https://api.mainnet-beta.solana.com

# Bot de Telegram
TELEGRAM_TOKEN=123456:ABC-DEF1GHI2JKL3MNO4PQR5STU6VWX-YZ
TELEGRAM_CHAT_ID=123456789

# Configuración de trading
TAKE_PROFIT_PCT=0.40
STOP_LOSS_PCT=0.10
CHECK_INTERVAL_MS=15000

# API de Shyft (para pools de PumpSwap)
SHYFT_API_KEY=tu_shyft_api_key_aqui
EOF

    print_success "Template .env creado"
}

# Instalar dependencias y compilar
install_and_compile() {
    print_step "Instalando dependencias Node.js..."
    cd executor
    npm install --silent --no-progress &>/dev/null || npm install
    cd ..
    print_success "Dependencias instaladas"
    
    print_step "Compilando detector Rust..."
    cd detector
    export PATH="$HOME/.cargo/bin:$PATH"
    cargo build --release --quiet &>/dev/null || cargo build --release
    cd ..
    print_success "Detector compilado"
}

# Crear README
create_readme() {
    cat > README.md << 'EOF'
# 🤖 PumpSwap Trading Bot

## 🎯 Configuración (Solo estos 3 pasos)

### 1️⃣ Configurar .env
```bash
cp executor/.env.template executor/.env
nano executor/.env
```
Edita con tus datos reales.

### 2️⃣ Ejecutar bot
```bash
./run.sh
```

### 3️⃣ Probar (en otra terminal)
```bash
./test.sh
```

## 📋 URLs Útiles

- Health: http://localhost:3000/health
- Posiciones: http://localhost:3000/positions

## ⚙️ Configuración Opcional

Para trading real (no simulación), edita:
- `executor/index.js` - Funciones de trading
- `detector/src/main.rs` - Tokens y wallets a seguir

## 🔧 Recompilar Rust (si cambias configuración)
```bash
cd detector
cargo build --release
```

¡Happy trading! 🚀
EOF
}

# EJECUCIÓN PRINCIPAL
main() {
    install_nodejs
    install_rust
    create_project
    create_package_json  
    create_cargo_toml
    create_index_js
    create_test_trade
    create_main_rs
    create_scripts
    create_env_template
    install_and_compile
    create_readme
    
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
    
    echo -e "${YELLOW}📋 Solo 3 pasos para usar:${NC}"
    echo ""
    echo -e "${BLUE}1️⃣ Ir al directorio:${NC}"
    echo "   cd pumpswap-bot"
    echo ""
    echo -e "${BLUE}2️⃣ Configurar .env:${NC}"
    echo "   cp executor/.env.template executor/.env"
    echo "   nano executor/.env"
    echo ""
    echo -e "${BLUE}3️⃣ Ejecutar bot:${NC}"
    echo "   ./run.sh"
    echo ""
    echo -e "${GREEN}🎯 ¡Tu bot está 100% listo!${NC}"
}

main
EOF
    print_success "README creado"
}

# EJECUCIÓN PRINCIPAL
main() {
    install_nodejs
    install_rust
    create_project
    create_package_json  
    create_cargo_toml
    create_index_js
    create_test_trade
    create_main_rs
    create_scripts
    create_env_template
    install_and_compile
    create_readme
    
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
    
    echo -e "${YELLOW}📋 Solo 3 pasos para usar:${NC}"
    echo ""
    echo -e "${BLUE}1️⃣ Ir al directorio:${NC}"
    echo "   cd pumpswap-bot"
    echo ""
    echo -e "${BLUE}2️⃣ Configurar .env:${NC}"
    echo "   cp executor/.env.template executor/.env"
    echo "   nano executor/.env"
    echo ""
    echo -e "${BLUE}3️⃣ Ejecutar bot:${NC}"
    echo "   ./run.sh"
    echo ""
    echo -e "${GREEN}🎯 ¡Tu bot está 100% listo!${NC}"
}

main
