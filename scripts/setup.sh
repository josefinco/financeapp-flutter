#!/bin/bash
set -e

echo "========================================="
echo "  FinanceApp - Setup do Ambiente Local"
echo "========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar Flutter
echo "1/5 - Verificando Flutter SDK..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter nao encontrado no PATH.${NC}"
    echo "Instale o Flutter SDK: https://docs.flutter.dev/get-started/install"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -1)
echo -e "${GREEN}$FLUTTER_VERSION${NC}"
echo ""

# 2. Verificar Dart
echo "2/5 - Verificando Dart SDK..."
if ! command -v dart &> /dev/null; then
    echo -e "${RED}Dart nao encontrado. Verifique a instalacao do Flutter.${NC}"
    exit 1
fi

DART_VERSION=$(dart --version 2>&1)
echo -e "${GREEN}$DART_VERSION${NC}"
echo ""

# 3. Configurar .env
echo "3/5 - Configurando variaveis de ambiente..."
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${YELLOW}Arquivo .env criado a partir do .env.example${NC}"
        echo -e "${YELLOW}IMPORTANTE: Edite o .env com suas credenciais antes de executar o app.${NC}"
    else
        echo -e "${RED}Arquivo .env.example nao encontrado.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Arquivo .env ja existe.${NC}"
fi
echo ""

# 4. Criar diretorios de assets
echo "Verificando diretorios de assets..."
mkdir -p assets/images assets/icons
echo -e "${GREEN}Diretorios de assets verificados.${NC}"
echo ""

# 5. Instalar dependencias
echo "4/5 - Instalando dependencias..."
flutter pub get
echo -e "${GREEN}Dependencias instaladas.${NC}"
echo ""

# 6. Gerar codigo
echo "5/5 - Gerando codigo (build_runner)..."
dart run build_runner build --delete-conflicting-outputs
echo -e "${GREEN}Codigo gerado com sucesso.${NC}"
echo ""

echo "========================================="
echo -e "${GREEN}  Setup concluido com sucesso!${NC}"
echo "========================================="
echo ""
echo "Proximos passos:"
echo "  1. Edite o arquivo .env com suas credenciais (Supabase, API)"
echo "  2. (Opcional) Configure Firebase: flutterfire configure --project=seu-projeto"
echo "  3. Execute o app: flutter run"
echo ""
