import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../bills/domain/entities/bill.dart';
import '../domain/entities/report.dart';

// ─── Bill Report Service ──────────────────────────────────────────────────────

/// Generates a formatted PDF report of bills for a given month and returns the
/// [File] so it can be shared via share_plus or other means.
class BillReportService {
  BillReportService._();

  static final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _monthFmt = DateFormat('MMMM yyyy', 'pt_BR');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  // ── Color palette ──────────────────────────────────────────────────────────

  static final _green = PdfColor.fromHex('#4CAF50');
  static final _red = PdfColor.fromHex('#FF4444');
  static final _orange = PdfColor.fromHex('#FF9800');
  static final _headerBg = PdfColor.fromHex('#1B6B45');
  static final _headerText = PdfColor.fromHex('#A8D5B5');
  static final _tableBorder = PdfColor.fromHex('#E8EBF0');
  static final _tableHeader = PdfColor.fromHex('#F2F5F9');
  static const _grey = PdfColors.grey700;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Generates a PDF report and saves it to the device's temp directory.
  /// Returns the generated [File].
  static Future<File> generate({
    required int month,
    required int year,
    required MonthlySummary summary,
    required List<Bill> bills,
    required ExpenseByCategoryResponse expensesByCategory,
  }) async {
    final doc = pw.Document(
      title: 'Relatório de Contas — Moneta',
      author: 'Moneta App',
    );

    final monthLabel = _monthFmt
        .format(DateTime(year, month))
        .toUpperCase();

    final paidBills = bills.where((b) => b.status == BillStatus.paid).toList();
    final pendingBills = bills.where((b) => b.status == BillStatus.pending).toList();
    final overdueBills = bills.where((b) => b.status == BillStatus.overdue).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox(height: 0) : _pageHeader(monthLabel),
        footer: (ctx) => _pageFooter(ctx),
        build: (ctx) => [
          // ── Cabeçalho ────────────────────────────────────────────────────
          _header(monthLabel),
          pw.SizedBox(height: 24),

          // ── Resumo Financeiro ─────────────────────────────────────────────
          _sectionTitle('RESUMO FINANCEIRO'),
          pw.SizedBox(height: 8),
          _financialSummaryRow(summary),
          pw.SizedBox(height: 8),
          _billsStatusRow(paidBills.length, pendingBills.length, overdueBills.length, summary),
          pw.SizedBox(height: 24),

          // ── Contas do Mês ─────────────────────────────────────────────────
          if (bills.isNotEmpty) ...[
            _sectionTitle('CONTAS DO MÊS (${bills.length} total)'),
            pw.SizedBox(height: 8),
            _billsTable(bills),
            pw.SizedBox(height: 24),
          ],

          // ── Gastos por Categoria ──────────────────────────────────────────
          if (expensesByCategory.categories.isNotEmpty) ...[
            _sectionTitle('GASTOS POR CATEGORIA'),
            pw.SizedBox(height: 8),
            _categoriesTable(expensesByCategory),
            pw.SizedBox(height: 24),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName =
        'moneta_relatorio_${year}_${month.toString().padLeft(2, '0')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  static pw.Widget _header(String monthLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Moneta',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Relatório de Contas',
                style: pw.TextStyle(color: _headerText, fontSize: 11),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                monthLabel,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Gerado em ${_dateFmt.format(DateTime.now())}',
                style: pw.TextStyle(color: _headerText, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageHeader(String monthLabel) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _tableBorder)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Moneta — Relatório de Contas',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text(monthLabel,
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey)),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _tableBorder)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Moneta — Gestão Financeira Inteligente',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2,
        color: _grey,
      ),
    );
  }

  static pw.Widget _financialSummaryRow(MonthlySummary s) {
    final balanceColor = s.balance >= 0 ? _green : _red;
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _tableBorder),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(14),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: _metricTile(
                label: 'Receitas',
                value: _currFmt.format(s.totalIncome),
                color: _green,
              ),
            ),
            _verticalDivider(),
            pw.Expanded(
              child: _metricTile(
                label: 'Despesas',
                value: _currFmt.format(s.totalExpense),
                color: _red,
              ),
            ),
            _verticalDivider(),
            pw.Expanded(
              child: _metricTile(
                label: 'Saldo',
                value: _currFmt.format(s.balance),
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _billsStatusRow(
    int paid,
    int pending,
    int overdue,
    MonthlySummary s,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _tableBorder),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(14),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: _metricTile(
                label: 'Pagas',
                value: '$paid',
                color: _green,
              ),
            ),
            _verticalDivider(),
            pw.Expanded(
              child: _metricTile(
                label: 'Pendentes',
                value: '$pending (${s.pendingBills})',
                color: _orange,
              ),
            ),
            _verticalDivider(),
            pw.Expanded(
              child: _metricTile(
                label: 'Vencidas',
                value: '$overdue (${s.overdueBills})',
                color: _red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _metricTile({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _verticalDivider() {
    return pw.Container(
      width: 1,
      height: 36,
      margin: const pw.EdgeInsets.symmetric(horizontal: 12),
      color: _tableBorder,
    );
  }

  static pw.Widget _billsTable(List<Bill> bills) {
    return pw.Table(
      border: pw.TableBorder.all(color: _tableBorder, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1.8),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tableHeader),
          children: [
            _cell('Nome', isHeader: true),
            _cell('Valor', isHeader: true),
            _cell('Vencimento', isHeader: true),
            _cell('Status', isHeader: true),
          ],
        ),
        // Rows
        ...bills.map(
          (b) => pw.TableRow(
            children: [
              _cell(b.name),
              _cell(_currFmt.format(b.amount)),
              _cell(_dateFmt.format(b.dueDate)),
              _cell(_statusLabel(b.status), color: _statusColor(b.status)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _categoriesTable(ExpenseByCategoryResponse r) {
    return pw.Table(
      border: pw.TableBorder.all(color: _tableBorder, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tableHeader),
          children: [
            _cell('Categoria', isHeader: true),
            _cell('Valor', isHeader: true),
            _cell('% do Total', isHeader: true),
          ],
        ),
        ...r.categories.map(
          (cat) => pw.TableRow(
            children: [
              _cell(cat.categoryName),
              _cell(_currFmt.format(cat.amount)),
              _cell('${cat.percentage.toStringAsFixed(1)}%'),
            ],
          ),
        ),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tableHeader),
          children: [
            _cell('TOTAL', isHeader: true),
            _cell(_currFmt.format(r.total), isHeader: true),
            _cell('100%', isHeader: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _statusLabel(BillStatus s) => switch (s) {
        BillStatus.pending => 'Pendente',
        BillStatus.paid => 'Pago',
        BillStatus.overdue => 'Vencida',
        BillStatus.cancelled => 'Cancelada',
      };

  static PdfColor _statusColor(BillStatus s) => switch (s) {
        BillStatus.pending => _orange,
        BillStatus.paid => _green,
        BillStatus.overdue => _red,
        BillStatus.cancelled => _grey,
      };
}
