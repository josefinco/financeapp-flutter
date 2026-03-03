// Wallet domain entity — manual (no code-gen needed).

enum WalletType { checking, savings, cash, investment, credit_card }

extension WalletTypeX on WalletType {
  String get label => switch (this) {
        WalletType.checking     => 'Conta Corrente',
        WalletType.savings      => 'Poupança',
        WalletType.cash         => 'Dinheiro',
        WalletType.investment   => 'Investimento',
        WalletType.credit_card  => 'Cartão de Crédito',
      };

  static WalletType fromString(String s) => switch (s) {
        'savings'     => WalletType.savings,
        'cash'        => WalletType.cash,
        'investment'  => WalletType.investment,
        'credit_card' => WalletType.credit_card,
        _             => WalletType.checking,
      };
}

class Wallet {
  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final double initialBalance;
  final double balance; // calculated: initial + transactions
  final String color;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.balance,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        id:             j['id'].toString(),
        userId:         j['user_id'].toString(),
        name:           j['name'] as String,
        type:           WalletTypeX.fromString(j['wallet_type'] as String? ?? j['type'] as String? ?? 'checking'),
        initialBalance: _parseDouble(j['initial_balance']),
        balance:        _parseDouble(j['balance']),
        color:          j['color'] as String? ?? '#4CAF50',
        icon:           j['icon'] as String? ?? 'account_balance_wallet',
        isActive:       j['is_active'] as bool? ?? true,
        createdAt:      DateTime.parse(j['created_at'].toString()),
        updatedAt:      DateTime.parse(j['updated_at'].toString()),
      );

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is String) return double.tryParse(v) ?? 0.0;
    return (v as num).toDouble();
  }
}
