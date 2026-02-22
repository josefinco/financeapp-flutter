# FinanceApp — Flutter

App mobile de gestão financeira pessoal com IA integrada.

## Stack

- **Flutter** 3.41+ / Dart 3.11+
- **Riverpod** (state management)
- **GoRouter** (navegação)
- **Supabase** (autenticação)
- **Dio + Retrofit** (HTTP client)
- **Freezed** (imutabilidade e serialização)
- **Hive CE** (cache local)
- **Firebase Messaging** (push notifications)
- **fl_chart** (gráficos)

## Estrutura Clean Architecture

```
lib/
  core/
    config/       # AppConfig (env vars)
    network/      # Dio client + interceptors
    theme/        # AppTheme
    router/       # GoRouter
    error/        # Failures, exceptions
    utils/        # Formatters, extensions
  features/
    auth/         # Login, cadastro
    bills/        # Contas a pagar ← Etapa 2 (implementado)
    transactions/ # Lançamentos
    wallets/      # Carteiras
    budgets/      # Orçamentos
    reports/      # Relatórios
    ai_chat/      # Chat com IA
    dashboard/    # Tela inicial
  shared/
    widgets/      # Widgets reutilizáveis
    extensions/   # Extensions Dart
    constants/    # Constantes globais
```

Cada feature segue o padrão:
```
feature/
  data/
    datasources/   # API / local
    models/        # JSON models
    repositories/  # implementações
  domain/
    entities/      # classes de domínio (Freezed)
    repositories/  # interfaces abstratas
    usecases/      # casos de uso
  presentation/
    pages/         # telas
    widgets/       # widgets da feature
    providers/     # Riverpod providers
```

## Setup

### 1. Pré-requisitos

- **Flutter SDK** >= 3.41.0
- **Dart SDK** >= 3.11.0
- **Java JDK** >= 17 (para build Android)
- Conta no [Supabase](https://supabase.com/) (para autenticação)
- Projeto no [Firebase](https://console.firebase.google.com/) (para push notifications)

### 2. Clone e instale dependências

```bash
git clone <repo>
cd financeapp-flutter
flutter pub get
```

### 3. Configure variáveis de ambiente

```bash
cp .env.example .env
```

Edite o `.env` com suas credenciais:

| Variável | Descrição |
|---|---|
| `SUPABASE_URL` | URL do seu projeto Supabase (ex: `https://xxx.supabase.co`) |
| `SUPABASE_ANON_KEY` | Chave anônima do Supabase |
| `API_BASE_URL` | URL base da API REST (ex: `http://10.0.2.2:8000/api/v1` para emulador Android) |

### 4. Configure Firebase (opcional para push notifications)

```bash
# Instale o FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure o projeto Firebase
flutterfire configure --project=your-firebase-project
```

Isso irá gerar o `google-services.json` (Android) e `GoogleService-Info.plist` (iOS).

### 5. Gere os arquivos de código

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Execute o app

```bash
flutter run
```

### Setup rápido (script)

Você pode usar o script automatizado:

```bash
./scripts/setup.sh
```

## Funcionalidades implementadas (Etapa 2)

- Listagem de contas por status (pendentes, vencidas, pagas)
- Card de conta com indicador visual de status
- Detalhe da conta em bottom sheet
- Marcar conta como paga (com criação automática de transação no backend)
- Dashboard com resumo e próximas contas
- Pull-to-refresh
- Login com Supabase

## Próximas etapas

- Etapa 3: Formulário de criar/editar conta, Transações, Carteiras
- Etapa 4: Orçamentos mensais
- Etapa 5: Gráficos e relatórios com fl_chart
- Etapa 6: Chat com IA (Claude API)
