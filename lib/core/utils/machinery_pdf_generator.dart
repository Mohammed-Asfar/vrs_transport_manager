import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/billing_mode.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';

class MachineryPdfGenerator {
  MachineryPdfGenerator._();

  static const _darkText = PdfColors.grey900;
  static const _mutedText = PdfColors.grey600;
  static const _accent = PdfColor.fromInt(0xFF0A84FF);
  static const _headerBg = PdfColor.fromInt(0xFFF2F2F7);
  static const _borderColor = PdfColors.grey300;

  static Future<void> generateAndPrint(MachineryRecord record) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bold = pw.TextStyle(font: fontBold, fontFallback: [font]);
    final smallBold = pw.TextStyle(
        fontSize: 9, font: fontBold, fontFallback: [font], color: _darkText);
    final small = pw.TextStyle(
        fontSize: 9, font: font, fontFallback: [font], color: _darkText);
    final smallMuted = pw.TextStyle(
        fontSize: 9, font: font, fontFallback: [font], color: _mutedText);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(record, bold, smallMuted),
              pw.SizedBox(height: 28),
              _buildMachineDetails(record, smallBold, small),
              pw.SizedBox(height: 20),
              _buildBillingDetails(record, smallBold, small),
              pw.SizedBox(height: 24),
              _buildFinancialSummary(record, smallBold, small, smallMuted),
              if (record.remarks.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildRemarks(record, smallBold, small),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name:
          'VRS_Machinery_${record.machineName}_${DateFormatter.toDisplay(record.date)}',
    );
  }

  static pw.Widget _buildHeader(
      MachineryRecord record, pw.TextStyle bold, pw.TextStyle muted) {
    final dateText = record.billingMode == BillingMode.monthlyRent &&
            record.startDate != null &&
            record.endDate != null
        ? '${DateFormatter.toDisplay(record.startDate!)} - ${DateFormatter.toDisplay(record.endDate!)}'
        : DateFormatter.toDisplay(record.date);

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VRS ENTERPRISES',
                style: bold.copyWith(fontSize: 20, letterSpacing: 1),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                record.location.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _mutedText,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('MACHINERY RECORD',
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: _accent,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(dateText, style: bold.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMachineDetails(
      MachineryRecord record, pw.TextStyle boldStyle, pw.TextStyle normalStyle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Machine', style: normalStyle.copyWith(color: _mutedText)),
                pw.SizedBox(height: 2),
                pw.Text(record.machineName.toUpperCase(),
                    style: boldStyle.copyWith(fontSize: 12)),
                if (record.machineNumber.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(record.machineNumber, style: normalStyle),
                ],
              ],
            ),
          ),
          if (record.operatorName.isNotEmpty)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Operator',
                      style: normalStyle.copyWith(color: _mutedText)),
                  pw.SizedBox(height: 2),
                  pw.Text(record.operatorName, style: boldStyle),
                ],
              ),
            ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _accent,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              record.billingMode == BillingMode.monthlyRent
                  ? 'MONTHLY RENT'
                  : 'PER LOAD',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillingDetails(
      MachineryRecord record, pw.TextStyle boldStyle, pw.TextStyle normalStyle) {
    if (record.billingMode == BillingMode.monthlyRent) {
      return _buildInfoTable([
        ['Monthly Rent', '₹${record.monthlyRent.toStringAsFixed(0)}'],
        if (record.startDate != null && record.endDate != null)
          [
            'Period',
            '${DateFormatter.toDisplay(record.startDate!)} - ${DateFormatter.toDisplay(record.endDate!)}'
          ],
        ['Total Amount', '₹${record.totalAmount.toStringAsFixed(0)}'],
      ], boldStyle, normalStyle);
    } else {
      return _buildInfoTable([
        ['Rate per Load', '₹${record.ratePerLoad.toStringAsFixed(0)}'],
        ['Total Loads', '${record.totalLoads}'],
        [
          'Total Amount',
          '₹${record.totalAmount.toStringAsFixed(0)} (${record.totalLoads} x ₹${record.ratePerLoad.toStringAsFixed(0)})'
        ],
      ], boldStyle, normalStyle);
    }
  }

  static pw.Widget _buildInfoTable(
      List<List<String>> rows, pw.TextStyle boldStyle, pw.TextStyle normalStyle) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        final isTotal = row[0] == 'Total Amount';
        return pw.TableRow(
          decoration: isTotal ? const pw.BoxDecoration(color: _headerBg) : null,
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: pw.Text(row[0], style: boldStyle),
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                row[1],
                style: isTotal
                    ? boldStyle.copyWith(color: _accent)
                    : normalStyle,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildFinancialSummary(
    MachineryRecord record,
    pw.TextStyle boldStyle,
    pw.TextStyle normalStyle,
    pw.TextStyle mutedStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Summary', style: boldStyle.copyWith(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text(
                  'Machine: ${record.machineName}', style: normalStyle),
              if (record.machineNumber.isNotEmpty)
                pw.Text('Number: ${record.machineNumber}',
                    style: normalStyle),
              pw.Text(
                'Mode: ${record.billingMode == BillingMode.monthlyRent ? 'Monthly Rent' : 'Per Load'}',
                style: normalStyle,
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 200,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _headerBg,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _borderColor, width: 0.5),
            ),
            child: pw.Column(
              children: [
                _summaryRow('Total Amount',
                    '₹${record.totalAmount.toStringAsFixed(0)}', normalStyle),
                pw.SizedBox(height: 6),
                _summaryRow('Diesel',
                    '- ₹${record.diesel.toStringAsFixed(0)}', mutedStyle),
                pw.SizedBox(height: 6),
                _summaryRow('Advance',
                    '- ₹${record.advance.toStringAsFixed(0)}', mutedStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        top: pw.BorderSide(color: _borderColor, width: 0.5)),
                  ),
                  child: _summaryRow(
                    'Balance',
                    '₹${record.balance.toStringAsFixed(0)}',
                    boldStyle.copyWith(fontSize: 12, color: _accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRemarks(
      MachineryRecord record, pw.TextStyle boldStyle, pw.TextStyle normalStyle) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Remarks', style: boldStyle),
          pw.SizedBox(height: 4),
          pw.Text(record.remarks, style: normalStyle),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(
      String label, String value, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }
}
