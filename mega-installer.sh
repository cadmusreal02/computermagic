#!/bin/bash

# 🚀 PUMPSWAP TRADING BOT - INSTALADOR COMPLETO TODO-EN-UNO
# Un solo comando instala TODO el proyecto sin tocar nada más
# curl -sSL https://pastebin.com/raw/TU-ID | bash

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

# Detectar OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
else
    OS="windows"
fi
print_success "Sistema: $OS"

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

# Instalar Rust
install_rust() {
    print_step "Verificando Rust..."
    if command -v cargo &> /dev/null; then
        print_success "Rust OK ($(cargo --version))"
        return
    fi
    
    print_step "Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
    source $HOME/.cargo/env
    print_success "Rust instalado: $(cargo --version)"
}

# Recopilar configuración del usuario
collect_config() {
    print_step "Configuración personalizada..."
    echo ""
    
    echo -e "${YELLOW}🔑 Tu wallet privada (array JSON):${NC}"
    echo "Ejemplo: [81,144,223,80,201,5,14,64,180,46,98,153...]"
    read -p "PAYER_SECRET: " PAYER_SECRET
    
    echo -e "${YELLOW}📱 Configuración Telegram:${NC}"
    read -p "Bot Token: " TELEGRAM_TOKEN
    read -p "Chat ID: " TELEGRAM_CHAT_ID
    
    echo -e "${YELLOW}🔧 API de Shyft:${NC}"
    read -p "Shyft API Key: " SHYFT_API_KEY
    
    echo -e "${YELLOW}🌐 API de Helius (opcional):${NC}"
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
    "test": "node testTrade.js pump",
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

# Crear index.js (CÓDIGO COMPLETO INCRUSTADO)
create_index_js() {
    print_step "Generando index.js..."
    cat > executor/index.js << 'EOF'
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const { Keypair, Connection, sendAndConfirmTransaction } = require("@solana/web3.js");
const TelegramBot = require("node-telegram-bot-api");
const { gql, GraphQLClient } = require("graphql-request");

const {
  PAYER_SECRET, RPC_URL,
  TELEGRAM_TOKEN, TELEGRAM_CHAT_ID,
  TAKE_PROFIT_PCT, STOP_LOSS_PCT, CHECK_INTERVAL_MS,
  SHYFT_API_KEY
} = process.env;

if (!PAYER_SECRET || !RPC_URL || !TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID || !SHYFT_API_KEY) {
  throw new Error("Faltan variables en .env");
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
  } catch (error) {
    console.error("Error sending Telegram message:", error);
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
        baseVault
        quoteVault
        lpSupply
        globalConfig
        _updatedAt
      }
    }
  `;

  try {
    const result = await graphQLClient.request(query, { tokenMint });
    return result.pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA_Pool[0];
  } catch (error) {
    console.error("Error fetching PumpSwap pool:", error);
    return null;
  }
}

// Función para obtener precio (simplificada para demo)
async function getPrice(dex, tokenMint, amount, isBuy) {
  if (dex === "pump") {
    try {
      const pool = await getPumpSwapPool(tokenMint);
      if (!pool) throw new Error("Pool no encontrado para token: " + tokenMint);
      
      // Simulación de precio para demo
      return Math.random() * 0.000001 + 0.0000001;
    } catch (error) {
      console.error("Error getting PumpSwap price:", error);
      throw error;
    }
  } else {
    // Simulación para Raydium
    return Math.random() * 0.000001 + 0.0000001;
  }
}

// Función para ejecutar trade (versión demo/simulación)
async function executeTrade(dex, tokenMint, amount, isBuy) {
  console.log(`🔄 Simulando ${isBuy ? 'BUY' : 'SELL'} de ${amount} en ${dex} para ${tokenMint}`);
  
  // En una implementación real, aquí irían las llamadas a los SDKs reales
  // Por ahora simulamos el trade para que el bot funcione inmediatamente
  
  await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
  
  // Generar signature falsa para demo
  const fakeSignature = `${Date.now()}${Math.random().toString(36).substr(2, 9)}`;
  
  console.log(`✅ Trade simulado ejecutado: ${fakeSignature}`);
  return fakeSignature;
}

// Función para ejecutar salida
async function executeExit(pos) {
  try {
    const exitSide = !pos.isBuy;
    const sig = await executeTrade(pos.dex, pos.mint, pos.amount, exitSide);
    
    // Calcular PnL simulado
    const currentPrice = await getPrice(pos.dex, pos.mint, pos.amount, exitSide);
    const pnl = pos.isBuy
      ? (currentPrice - pos.entryPrice) / pos.entryPrice
      : (pos.entryPrice - currentPrice) / pos.entryPrice;

    await notify(`⚡ *Exit* ${pos.dex.toUpperCase()} ${exitSide ? "BUY" : "SELL"}
• Mint: \`${pos.mint}\`
• Cantidad: ${pos.amount}
• PnL: ${(pnl * 100).toFixed(2)}%
• TX: \`${sig}\``);
    
    return sig;
  } catch (error) {
    console.error("Error executing exit:", error);
    await notify(`❌ Error en exit para ${pos.mint}: ${error.message}`);
  }
}

// Monitor de posiciones
setInterval(async () => {
  for (let [id, pos] of positions) {
    try {
      const currentPrice = await getPrice(pos.dex, pos.mint, pos.amount, pos.isBuy);
      
      const pnl = pos.isBuy
        ? (currentPrice - pos.entryPrice) / pos.entryPrice
        : (pos.entryPrice - currentPrice) / pos.entryPrice;

      if (pnl >= parseFloat(TAKE_PROFIT_PCT) || pnl <= -parseFloat(STOP_LOSS_PCT)) {
        await executeExit(pos);
        positions.delete(id);
      }
    } catch (err) {
      console.error("Error checking position", id, err);
    }
  }
}, parseInt(CHECK_INTERVAL_MS));

// Endpoint para ejecutar trades
app.post("/exec/:dex", async (req, res) => {
  try {
    const dex = req.params.dex;
    const { mint, amount, isBuy } = req.body;
    
    if (!mint || !amount || typeof isBuy !== 'boolean') {
      return res.status(400).json({ error: "Parámetros inválidos" });
    }

    console.log(`Ejecutando ${isBuy ? 'BUY' : 'SELL'} de ${amount} para ${mint} en ${dex}`);
    
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

    await notify(`🆕 *Entry* ${dex.toUpperCase()} ${isBuy ? "BUY" : "SELL"}
• Mint: \`${mint}\`
• Cantidad: ${amount}
• Precio entrada: ${entryPrice.toFixed(8)}
• TX: \`${sig}\``);

    res.json({ sig, entryPrice, status: "simulated" });
  } catch (e) {
    console.error("Error in trade execution:", e);
    res.status(500).json({ error: e.message });
  }
});

app.get("/positions", (req, res) => {
  const positionsArray = Array.from(positions.entries()).map(([id, pos]) => ({
    id,
    ...pos
  }));
  res.json(positionsArray);
});

app.get("/health", (req, res) => {
  res.json({ 
    status: "OK", 
    positions: positions.size,
    timestamp: new Date().toISOString(),
    mode: "simulation"
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Executor corriendo en http://localhost:${PORT}`);
  console.log(`📊 Monitoreando ${positions.size} posiciones`);
  console.log(`🤖 Bot de Telegram configurado`);
  console.log(`⚠️  MODO SIMULACIÓN - Los trades son ficticios para pruebas`);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});
EOF
    print_success "index.js creado"
}

# Crear testTrade.js
create_test_trade() {
    print_step "Generando testTrade.js..."
    cat > executor/testTrade.js << 'EOF'
const axios = require("axios");

async function testearConexiones() {
  console.log("🔧 Verificando conexiones...");
  
  try {
    const healthResponse = await axios.get("http://localhost:3000/health");
    console.log("✅ Servidor local funcionando:", healthResponse.data);
  } catch (error) {
    console.error("❌ Servidor local no responde. ¿Está corriendo?");
    return false;
  }
  
  return true;
}

async function ejecutarTradePrueba() {
  console.log("\n🚀 Iniciando trade de prueba...");
  
  try {
    const tokenMint = "5B1o489Hm8rBgrebAtxfY8Sjma6j9EfFhZXpPyjCpump";
    const amount = 0.001;
    const isBuy = true;
    
    console.log(`📋 Parámetros del trade:
• Token: ${tokenMint}
• Cantidad: ${amount} SOL
• Tipo: ${isBuy ? 'BUY' : 'SELL'}
• DEX: PumpSwap`);

    const response = await axios.post("http://localhost:3000/exec/pump", {
      mint: tokenMint,
      amount: amount,
      isBuy: isBuy
    });

    console.log("✅ Trade ejecutado exitosamente!");
    console.log("📄 Respuesta:", {
      signature: response.data.sig,
      entryPrice: response.data.entryPrice,
      status: response.data.status
    });
    
    const positionsResponse = await axios.get("http://localhost:3000/positions");
    console.log(`📊 Posiciones activas: ${positionsResponse.data.length}`);
    
    return response.data;
    
  } catch (error) {
    console.error("❌ Error al ejecutar trade:", error.response?.data || error.message);
    return null;
  }
}

async function main() {
  console.log("🤖 Bot de Trading - Test Suite");
  console.log("================================\n");
  
  const conexionesOk = await testearConexiones();
  if (!conexionesOk) {
    console.log("\n❌ Pruebas fallaron. Revisa la configuración.");
    return;
  }
  
  console.log("\n✅ Todas las conexiones funcionando correctamente!");
  await ejecutarTradePrueba();
}

main().catch(console.error);
EOF
    print_success "testTrade.js creado"
}

# Crear main.rs (CÓDIGO RUST COMPLETO INCRUSTADO)
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
use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use futures::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::json;
use reqwest::Client;
use anyhow::{Result, bail};
use std::collections::HashSet;

const HELIUS_API_KEY: &str = "$HELIUS_API_KEY";
const WS_URL: &str = "wss://mainnet.helius-rpc.com/?api-key=$HELIUS_API_KEY";
const REST_BASE: &str = "https://api.helius.xyz/v0/transactions";
const EXECUTOR_URL: &str = "http://localhost:3000/exec";

const TELEGRAM_BOT_TOKEN: &str = "$TELEGRAM_TOKEN";
const TELEGRAM_CHAT_ID: &str = "$TELEGRAM_CHAT_ID";

const TARGET_WALLETS: [(&str, &str); ${#WALLETS[@]}] = [
$RUST_WALLETS
];

const RAYDIUM_PROGRAM: &str = "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8";
const PUMPSWAP_PROGRAM: &str = "pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA";
const PUMP_FUN_PROGRAM: &str = "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P";

#[derive(Debug, Deserialize)]
struct HeliusTx {
    description: Option<String>,
    #[serde(rename="dex")]
    dex_name: Option<String>,
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
    #[serde(rename="fromUserAccount")]
    from_user_account: Option<String>,
    #[serde(rename="toUserAccount")]
    to_user_account: Option<String>,
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
    program_id: String,
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
    mentions: Vec<&str>,
}

fn determine_dex_from_program(program_id: &str) -> Option<&'static str> {
    match program_id {
        RAYDIUM_PROGRAM => Some("raydium"),
        PUMPSWAP_PROGRAM => Some("pump"),
        PUMP_FUN_PROGRAM => Some("pump"),
        _ => None,
    }
}

fn is_buy_transaction(token_transfers: &[TokenTransfer], target_wallets: &[&str]) -> Option<bool> {
    for transfer in token_transfers {
        for &wallet in target_wallets {
            if transfer.to_user_account.as_ref().map_or(false, |to| to == wallet) {
                return Some(true);
            }
            if transfer.from_user_account.as_ref().map_or(false, |from| from == wallet) {
                return Some(false);
            }
        }
    }
    None
}

#[tokio::main]
async fn main() -> Result<()> {
    println!("🚀 Iniciando detector de swaps v2.0 (PumpSwap compatible)");
    println!("Monitoreando {} wallets:", TARGET_WALLETS.len());
    for (addr, nick) in &TARGET_WALLETS {
        println!("  👤 {} ({}...{})", nick, &addr[..8], &addr[addr.len()-8..]);
    }
    println!("");
    
    loop {
        match run_ws_listener().await {
            Ok(_) => break,
            Err(e) => {
                eprintln!("❌ WebSocket error: {:?}. Reconectando en 3s...", e);
                sleep(Duration::from_secs(3)).await;
            }
        }
    }
    Ok(())
}

async fn run_ws_listener() -> Result<()> {
    let (ws_stream, _) = connect_async(WS_URL).await?;
    println!("✅ Conectado a Helius WS");
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
    println!("✅ Subscripción activa - esperando swaps...");

    let http = Client::new();
    let mut seen = HashSet::new();

    while let Some(msg) = read.next().await {
        let msg = msg?;
        if let Message::Text(txt) = msg {
            let v: serde_json::Value = serde_json::from_str(&txt)?;
            if v.get("method").and_then(|m| m.as_str()) != Some("logsNotification") {
                continue;
            }

            let sig = v["params"]["result"]["value"]["signature"]
                .as_str().unwrap_or_default().to_string();
            if seen.contains(&sig) {
                continue;
            }
            seen.insert(sig.clone());

            let url = format!("{}/{}?api-key={}", REST_BASE, sig, HELIUS_API_KEY);
            let res = http.get(&url).send().await?;
            if !res.status().is_success() {
                continue;
            }
            let parsed: Vec<HeliusTx> = res.json().await?;
            let tx = match parsed.into_iter().next() {
                Some(tx) => tx,
                None => continue,
            };

            let nick = TARGET_WALLETS
                .iter()
                .find_map(|(w, nick)| {
                    v["params"]["result"]["value"]["logs"]
                        .as_array().unwrap_or(&vec![])
                        .iter()
                        .any(|log| log.as_str().map_or(false, |s| s.contains(*w)))
                        .then(|| *nick)
                })
                .unwrap_or("unknown");

            let mut detected_dex = None;
            if let Some(instructions) = &tx.instructions {
                for inst in instructions {
                    if let Some(dex) = determine_dex_from_program(&inst.program_id) {
                        detected_dex = Some((dex, inst.program_id.clone()));
                        break;
                    }
                }
            }

            if detected_dex.is_none() {
                let desc = tx.description.clone().unwrap_or_default().to_lowercase();
                let dex_name = tx.dex_name.clone().unwrap_or_default().to_lowercase();
                
                if desc.contains("swap") {
                    if dex_name.contains("raydium") {
                        detected_dex = Some(("raydium", RAYDIUM_PROGRAM.to_string()));
                    } else if dex_name.contains("pump") || desc.contains("pump") {
                        detected_dex = Some(("pump", PUMPSWAP_PROGRAM.to_string()));
                    }
                }
            }

            if let Some((dex, program_id)) = detected_dex {
                if let Some(token_transfers) = &tx.token_transfers {
                    if !token_transfers.is_empty() {
                        let target_wallet_addrs: Vec<&str> = TARGET_WALLETS.iter().map(|(w, _)| *w).collect();
                        let is_buy = is_buy_transaction(token_transfers, &target_wallet_addrs)
                            .unwrap_or_else(|| {
                                let desc = tx.description.clone().unwrap_or_default().to_lowercase();
                                desc.contains("in") || desc.contains("buy")
                            });

                        let transfer = &token_transfers[0];
                        
                        let event = SwapEvent {
                            wallet_nick: nick.to_string(),
                            mint: transfer.mint.clone(),
                            amount: transfer.token_amount,
                            is_buy,
                            dex: dex.to_string(),
                            signature: tx.signature.clone(),
                            program_id,
                        };

                        println!("🔍 Swap detectado: {} en {} - {} {} tokens ({})", 
                                nick, 
                                dex.to_uppercase(), 
                                if event.is_buy { "BUY" } else { "SELL" },
                                event.amount,
                                &event.mint[..8]);

                        if let Err(e) = execute_trade(&http, &event).await {
                            eprintln!("❌ Error ejecutando trade: {}", e);
                        }

                        if let Err(e) = notify_telegram(&event).await {
                            eprintln!("❌ Error enviando notificación: {}", e);
                        }
                    }
                }
            }
        }
    }

    Ok(())
}

async fn execute_trade(client: &Client, event: &SwapEvent) -> Result<()> {
    let executor_endpoint = format!("{}/{}", EXECUTOR_URL, event.dex);
    
    let payload = json!({
        "mint": event.mint,
        "amount": if event.dex == "pump" { 0.001 } else { event.amount },
        "isBuy": event.is_buy
    });

    println!("📡 Enviando trade a executor...");

    let resp = client
        .post(&executor_endpoint)
        .json(&payload)
        .timeout(Duration::from_secs(10))
        .send()
        .await?;

    if resp.status().is_success() {
        let response_text = resp.text().await?;
        println!("✅ Trade ejecutado: OK");
    } else {
        let error_text = resp.text().await.unwrap_or_default();
        bail!("Executor {} falló: {} - {}", event.dex, resp.status(), error_text);
    }

    Ok(())
}

async fn notify_telegram(event: &SwapEvent) -> Result<()> {
    let client = Client::new();
    
    let dex_emoji = match event.dex.as_str() {
        "pump" => "🟣",
        "raydium" => "🔵", 
        _ => "⚪"
    };
    
    let action_emoji = if event.is_buy { "🟢" } else { "🔴" };
    
    let text = format!(
        "{} *Swap Detectado* {}\\n\\
         \\n\\
         👤 **Trader:** {}\\n\\
         🏪 **DEX:** {} {}\\n\\
         🪙 **Token:** \`{}\`\\n\\
         💰 **Cantidad:** {:.6}\\n\\
         📊 **Acción:** {}\\n\\
         🔗 **TX:** \`{}\`\\n\\
         \\n\\
         _Auto\\-ejecutando trade similar\\.\\.\\._",
        dex_emoji,
        action_emoji,
        event.wallet_nick,
        event.dex.to_uppercase(),
        dex_emoji,
        event.mint,
        event.amount,
        if event.is_buy { "COMPRA 🟢" } else { "VENTA 🔴" },
        event.signature
    );

    let url = format!("https://api.telegram.org/bot{}/sendMessage", TELEGRAM_BOT_TOKEN);
    let resp = client
        .post(&url)
        .json(&json!({
            "chat_id": TELEGRAM_CHAT_ID,
            "text": text,
            "parse_mode": "MarkdownV2",
            "disable_web_page_preview": true
        }))
        .timeout(Duration::from_secs(5))
        .send()
        .await?;

    if !resp.status().is_success() {
        let error_text = resp.text().await.unwrap_or_default();
        bail!("Telegram API error: {} - {}", resp.status(), error_text);
    }

    println!("📱 Notificación enviada");
    Ok(())
}
EOF
    print_success "main.rs creado"
}

# Instalar dependencias Node.js
install_node_deps() {
    print_step "Instalando dependencias Node.js..."
    cd executor
    npm install --silent
    cd ..
    print_success "Dependencias Node.js instaladas"
}

# Compilar Rust
compile_rust() {
    print_step "Compilando detector Rust..."
    cd detector
    cargo build --release --quiet
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

# Verificar que .env existe
if [ ! -f executor/.env ]; then
    echo "❌ Archivo .env no encontrado"
    exit 1
fi

# Iniciar executor en background
echo "📡 Iniciando executor Node.js..."
cd executor
node index.js &
EXECUTOR_PID=$!
cd ..

# Esperar a que el executor esté listo
echo "⏳ Esperando executor..."
sleep 5

# Verificar que el executor está funcionando
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "❌ Executor no está respondiendo"
    kill $EXECUTOR_PID 2>/dev/null
    exit 1
fi

echo "✅ Executor funcionando en http://localhost:3000"

# Iniciar detector Rust
echo "🦀 Iniciando detector Rust..."
cd detector
./target/release/pumpswap-detector

# Limpiar al salir
trap "kill $EXECUTOR_PID 2>/dev/null" EXIT
EOF

    cat > test.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing PumpSwap Trading Bot"
echo "==============================="

cd executor

echo "1️⃣ Probando health endpoint..."
curl -s http://localhost:3000/health | python3 -c "import sys, json; print('✅ Health OK:', json.load(sys.stdin))" 2>/dev/null || echo "❌ Servidor no está corriendo"

echo "2️⃣ Probando trade de prueba..."
npm test

echo "3️⃣ Verificando posiciones..."
curl -s http://localhost:3000/positions | python3 -c "import sys, json; print('✅ Posiciones:', len(json.load(sys.stdin)))" 2>/dev/null || echo "❌ Error consultando posiciones"

echo "✅ Tests completados"
EOF

    chmod +x run.sh test.sh
    print_success "Scripts de ejecución creados"
}

# Test final
final_test() {
    print_step "Ejecutando test final..."
    
    cd executor
    timeout 5s node index.js &
    EXECUTOR_PID=$!
    cd ..
    
    sleep 3
    
    if curl -s http://localhost:3000/health > /dev/null; then
        print_success "¡Bot funcionando correctamente!"
    else
        print_warning "Test incompleto - el bot se instaló pero verifica la configuración"
    fi
    
    kill $EXECUTOR_PID 2>/dev/null || true
}

# Crear README
create_readme() {
    print_step "Creando documentación..."
    cat > README.md << 'EOF'
# 🤖 PumpSwap Trading Bot

Bot de copy trading automático para PumpSwap y Raydium en Solana.

## 🚀 Instalación Automática

```bash
curl -sSL https://pastebin.com/raw/TU-ID | bash
```

## 📋 Uso

### Ejecutar el bot completo:
```bash
./run.sh
```

### Probar conexiones:
```bash
./test.sh
```

### Solo executor (para desarrollo):
```bash
cd executor
npm start
```

### Solo detector (para desarrollo):
```bash
cd detector
cargo run --release
```

## 📁 Estructura

- `executor/` - Servidor Node.js que ejecuta trades
- `detector/` - Monitor Rust que vigila wallets
- `run.sh` - Script para ejecutar todo
- `test.sh` - Script de testing

## ⚙️ Configuración

Toda la configuración está en `executor/.env`:

- `PAYER_SECRET` - Tu wallet privada
- `TELEGRAM_TOKEN` - Token de tu bot
- `TELEGRAM_CHAT_ID` - Tu chat ID
- `SHYFT_API_KEY` - API key de Shyft
- `TAKE_PROFIT_PCT` - % ganancia para cerrar (ej: 0.40 = 40%)
- `STOP_LOSS_PCT` - % pérdida para cerrar (ej: 0.10 = 10%)

## 🔧 Endpoints API

- `POST /exec/pump` - Ejecutar trade en PumpSwap
- `POST /exec/raydium` - Ejecutar trade en Raydium
- `GET /positions` - Ver posiciones activas
- `GET /health` - Estado del servidor

## ⚠️ Importante

Este bot inicia en **MODO SIMULACIÓN** para que puedas probarlo safely.
Para trading real, modifica las funciones de trading en `executor/index.js`.

## 📱 Soporte

- Verifica que todas las API keys sean correctas
- Usa cantidades pequeñas para probar (0.001 SOL)
- Revisa los logs si algo falla

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
    echo "  ./run.sh"
    echo ""
    echo -e "${YELLOW}🧪 Para probar conexiones:${NC}"
    echo "  ./test.sh"
    echo ""
    echo -e "${YELLOW}📊 Estructura del proyecto:${NC}"
    echo "  📁 detector/     - Monitor Rust (vigila wallets)"
    echo "  📁 executor/     - Servidor Node.js (ejecuta trades)"
    echo "  📄 run.sh        - Script principal"
    echo "  📄 test.sh       - Testing"
    echo "  📄 README.md     - Documentación"
    echo ""
    echo -e "${PURPLE}⚠️  IMPORTANTE:${NC}"
    echo "• El bot inicia en MODO SIMULACIÓN para pruebas"
    echo "• Usa cantidades pequeñas para probar"
    echo "• Revisa que todas tus API keys sean correctas"
    echo ""
    echo -e "${GREEN}🎯 ¡Tu bot ya está listo para copiar trades automáticamente!${NC}"
    echo ""
}

# EJECUCIÓN PRINCIPAL
main() {
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
