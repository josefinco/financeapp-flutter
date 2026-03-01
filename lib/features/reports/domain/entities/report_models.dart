// Plain Dart models for Reports feature (no code generation needed)

class MonthlySummary {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int pendingBills;
  final int overdueBills;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.pendingBills,
    required this.overdueBills,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        month: json['month'],
        year: json['year'],
        totalIncome: _parseDouble(json['total_income']),
        totalExpense: _parseDouble(json['total_expense']),
        balance: _parseDouble(json['balance']),
        pendingBills: json['pending_bills'],
        overdueBills: json['overdue_bills'],
      );
}

class CategoryExpense {
  final String? categoryId;
  final String categoryName;
  final String categoryColor;
  final double amount;
  final double percentage;

  CategoryExpense({
    this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.amount,
    required this.percentage,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) => CategoryExpense(
        categoryId: json['category_id'],
        categoryName: json['category_name'],
        categoryColor: json['category_color'],
        amount: _parseDouble(json['amount']),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class ExpenseByCategoryResponse {
  final int month;
  final int year;
  final double total;
  final List<CategoryExpense> categories;

  ExpenseByCategoryResponse({
    required this.month,
    required this.year,
    required this.total,
    required this.categories,
  });

  factory ExpenseByCategoryResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseByCategoryResponse(
        month: json['month'],
        year: json['year'],
        total: _parseDouble(json['total']),
        categories: (json['categories'] as List)
            .map((e) => CategoryExpense.fromJson(e))
            .toList(),
      );
}

class MonthlyEvolutionResponse {
  final List<MonthlySummary> months;

  MonthlyEvolutionResponse({required this.months});

  factory MonthlyEvolutionResponse.fromJson(Map<String, dynamic> json) =>
      MonthlyEvolutionResponse(
        months: (json['months'] as List)
            .map((e) => MonthlySummary.fromJson(e))
            .toList(),
      );
}

class WalletBalanceItem {
  final String walletId;
  final String walletName;
  final double balance;
  final String walletType;
  final String color;

  WalletBalanceItem({
    required this.walletId,
    required this.walletName,
    required this.balance,
    required this.walletType,
    required this.color,
  });

  factory WalletBalanceItem.fromJson(Map<String, dynamic> json) => WalletBalanceItem(
        walletId: json['wallet_id'],
        walletName: json['wallet_name'],
        balance: _parseDouble(json['balance']),
        walletType: json['wallet_type'],
        color: json['color'],
      );
}

class WalletBalancesResponse {
  final List<WalletBalanceItem> wallets;
  final double totalBalance;

  WalletBalancesResponse({required this.wallets, required this.totalBalance});

  factory WalletBalancesResponse.fromJson(Map<String, dynamic> json) =>
      WalletBalancesResponse(
        wallets: (json['wallets'] as List)
            .map((e) => WalletBalanceItem.fromJson(e))
            .toList(),
        totalBalance: _parseDouble(json['total_balance']),
      );
}

double _parseDouble(dynamic value) =>
    value is String ? double.parse(value) : (value as num).toDouble();
