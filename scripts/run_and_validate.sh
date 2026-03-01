#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# FinanceApp Flutter — Script de Validação e Execução
# Execute a partir da raiz do projeto: bash scripts/run_and_validate.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BACKEND_URL="https://financeapp-backend-xsy2.onrender.com"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║         FinanceApp — Validação e Execução            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 1. Checar Flutter ────────────────────────────────────────────────────────
echo "▶ [1/5] Verificando Flutter SDK..."
if ! command -v flutter &>/dev/null; then
  echo "  ✕ Flutter não encontrado. Instale em: https://docs.flutter.dev/get-started/install"
  exit 1
fi
flutter --version | head -1
echo "  ✓ Flutter OK"
echo ""

# ── 2. flutter pub get ───────────────────────────────────────────────────────
echo "▶ [2/5] Instalando dependências (flutter pub get)..."
flutter pub get
echo "  ✓ Dependências instaladas"
echo ""

# ── 3. flutter analyze ──────────────────────────────────────────────────────
echo "▶ [3/5] Analisando código (flutter analyze)..."
if flutter analyze --no-fatal-infos 2>&1; then
  echo "  ✓ Sem erros de compilação"
else
  echo ""
  echo "  ⚠ Foram encontrados avisos. Revise antes de prosseguir."
  echo "    Para forçar a execução mesmo assim, remova o 'set -e' deste script."
fi
echo ""

# ── 4. Checar backend ────────────────────────────────────────────────────────
echo "▶ [4/5] Testando conexão com o backend..."
HTTP_STATUS=$(curl -s -o /tmp/health_resp.json -w "%{http_code}" \
  --max-time 15 \
  "$BACKEND_URL/health" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "  ✓ Backend online: $(cat /tmp/health_resp.json)"
elif [ "$HTTP_STATUS" = "000" ]; then
  echo "  ⚠ Backend não respondeu (pode estar iniciando no Render — aguarde 1-2 min)"
  echo "    URL: $BACKEND_URL/health"
else
  echo "  ⚠ Backend retornou HTTP $HTTP_STATUS"
  echo "    URL: $BACKEND_URL/health"
fi
echo ""

# ── 5. Listar dispositivos e executar ────────────────────────────────────────
echo "▶ [5/5] Dispositivos disponíveis:"
flutter devices
echo ""
echo "────────────────────────────────────────────────────────"
echo "  Para executar o app, use um dos comandos abaixo:"
echo ""
echo "  # Android (emulador ou dispositivo conectado)"
echo "  flutter run -d android"
echo ""
echo "  # iOS (apenas macOS com Xcode)"
echo "  flutter run -d ios"
echo ""
echo "  # Chrome (web)"
echo "  flutter run -d chrome"
echo ""
echo "  # macOS nativo"
echo "  flutter run -d macos"
echo ""
echo "  # Modo verbose (exibe logs de rede detalhados)"
echo "  flutter run -d android --verbose"
echo "────────────────────────────────────────────────────────"
echo ""

# Pergunta se quer executar agora
read -p "  Executar agora? (s/N): " RUN_NOW
if [[ "$RUN_NOW" =~ ^[Ss]$ ]]; then
  echo ""
  read -p "  Informe o device-id (ex: emulator-5554, chrome, macos): " DEVICE_ID
  flutter run -d "$DEVICE_ID"
fi
