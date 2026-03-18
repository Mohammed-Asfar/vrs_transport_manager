import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';

class PdfGenerator {
  PdfGenerator._();

  static const _darkText = PdfColors.grey900;
  static const _mutedText = PdfColors.grey600;
  static const _accent = PdfColor.fromInt(0xFF0A84FF);
  static const _headerBg = PdfColor.fromInt(0xFFF2F2F7);
  static const _borderColor = PdfColors.grey300;

  static Future<void> generateAndPrint(TransportRecord record) async {
    final pdf = pw.Document();

    // Load a font that supports the ₹ symbol
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bold = pw.TextStyle(font: fontBold, fontFallback: [font]);
    final smallBold = pw.TextStyle(fontSize: 9, font: fontBold, fontFallback: [font], color: _darkText);
    final small = pw.TextStyle(fontSize: 9, font: font, fontFallback: [fontBold], color: _darkText);
    final smallMuted = pw.TextStyle(fontSize: 9, font: font, fontFallback: [fontBold], color: _mutedText);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              _buildHeader(record, bold),
              pw.SizedBox(height: 28),

              // ─── Trip Table ───
              _buildTripTable(context, record, smallBold, small),
              pw.SizedBox(height: 24),

              // ─── Financial Summary ───
              _buildFinancialSummary(record, smallBold, small, smallMuted),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'VRS_Transport_${record.location}_${DateFormatter.toDisplay(record.date)}',
    );
  }

  static pw.Widget _buildHeader(TransportRecord record, pw.TextStyle bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
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
              if (record.transporter.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Transporter: ${record.transporter}',
                  style: pw.TextStyle(fontSize: 9, color: _mutedText),
                ),
              ],
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('TRANSPORT RECORD',
                  style: pw.TextStyle(fontSize: 9, color: _accent, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(DateFormatter.toDisplay(record.date),
                  style: bold.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTripTable(
    pw.Context context,
    TransportRecord record,
    pw.TextStyle headerStyle,
    pw.TextStyle cellStyle,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(52),
        5: const pw.FixedColumnWidth(65),
        6: const pw.FixedColumnWidth(40),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _tableHeaderCell('#', headerStyle),
            _tableHeaderCell('Vehicle No', headerStyle),
            _tableHeaderCell('Chainage', headerStyle),
            _tableHeaderCell('KM', headerStyle),
            _tableHeaderCell('Rate/KM', headerStyle),
            _tableHeaderCell('Amount', headerStyle),
            _tableHeaderCell('Loads', headerStyle),
          ],
        ),
        // Data rows
        ...record.trips.map((trip) => pw.TableRow(
              children: [
                _tableCell('${trip.sNo}', cellStyle),
                _tableCell(trip.vehicleNo, cellStyle, align: pw.Alignment.centerLeft),
                _tableCell(trip.chainage.toStringAsFixed(0), cellStyle),
                _tableCell(trip.km.toStringAsFixed(0), cellStyle),
                _tableCell(trip.ratePerKm.toStringAsFixed(0), cellStyle),
                _tableCell(trip.amountPerTrip.toStringAsFixed(0), cellStyle),
                _tableCell('${trip.noOfLoads}', cellStyle),
              ],
            )),
        // Total row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableHeaderCell(
              '₹${record.totalAmount.toStringAsFixed(0)}',
              headerStyle.copyWith(color: _accent),
            ),
            _tableHeaderCell(
              '${record.totalLoads}',
              headerStyle.copyWith(color: _accent),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _tableCell(String text, pw.TextStyle style,
      {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _buildFinancialSummary(
    TransportRecord record,
    pw.TextStyle boldStyle,
    pw.TextStyle normalStyle,
    pw.TextStyle mutedStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: vehicle summary
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Summary', style: boldStyle.copyWith(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text('Vehicles: ${record.trips.length}', style: normalStyle),
              pw.Text('Total Loads: ${record.totalLoads}', style: normalStyle),
            ],
          ),
        ),
        // Right: financial breakdown
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
                _summaryRow('Total Amount', '₹${record.totalAmount.toStringAsFixed(0)}', normalStyle),
                pw.SizedBox(height: 6),
                _summaryRow('Diesel', '- ₹${record.diesel.toStringAsFixed(0)}', mutedStyle),
                pw.SizedBox(height: 6),
                _summaryRow('Advance', '- ₹${record.advance.toStringAsFixed(0)}', mutedStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.5)),
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

  static pw.Widget _summaryRow(String label, String value, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }
}
