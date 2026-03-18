import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';

class ReportPdfGenerator {
  ReportPdfGenerator._();

  static const _darkText = PdfColors.grey900;
  static const _mutedText = PdfColors.grey600;
  static const _accent = PdfColor.fromInt(0xFF0A84FF);
  static const _headerBg = PdfColor.fromInt(0xFFF2F2F7);
  static const _borderColor = PdfColors.grey300;
  static const _successColor = PdfColor.fromInt(0xFF30D158);

  static Future<void> generateAndPrint(ReportData data) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bold = pw.TextStyle(font: fontBold, fontFallback: [font]);
    final smallBold = pw.TextStyle(
        fontSize: 9, font: fontBold, fontFallback: [font], color: _darkText);
    final small = pw.TextStyle(
        fontSize: 9, font: font, fontFallback: [fontBold], color: _darkText);
    final smallMuted = pw.TextStyle(
        fontSize: 9, font: font, fontFallback: [fontBold], color: _mutedText);

    // Page 1: Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(data),
            pw.SizedBox(height: 24),
            _buildOverviewGrid(data.overview, smallBold, small),
            pw.SizedBox(height: 24),
            _buildSummaryTable(data, smallBold, small),
          ],
        ),
      ),
    );

    // Page 2+: One multi-page section per group
    for (final group in data.groups) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
          header: (context) => _buildGroupHeader(group, data.config, bold),
          build: (context) => [
            pw.SizedBox(height: 16),
            _buildGroupTripTable(group, data.config, smallBold, small),
            pw.SizedBox(height: 20),
            _buildGroupFinancialFooter(group, smallBold, small, smallMuted),
          ],
        ),
      );
    }

    final dateRange =
        '${DateFormatter.toDisplay(data.config.startDate)}_${DateFormatter.toDisplay(data.config.endDate)}';

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'VRS_Summary_$dateRange',
    );
  }

  // ─── Header ───

  static pw.Widget _buildHeader(ReportData data) {
    final viewLabel = data.config.viewMode == ReportViewMode.transporter
        ? 'Transporter-wise'
        : 'Vehicle-wise';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('VRS ENTERPRISES',
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1)),
              pw.SizedBox(height: 2),
              pw.Text('TRANSPORT SUMMARY REPORT',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: _accent,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(viewLabel,
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: _mutedText,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormatter.toRange(
                    data.config.startDate, data.config.endDate),
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Overview Grid ───

  static pw.Widget _buildOverviewGrid(
    ReportOverview overview,
    pw.TextStyle boldStyle,
    pw.TextStyle normalStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _overviewItem('Records', '${overview.totalRecords}', boldStyle, normalStyle),
          _overviewItem('Transporters', '${overview.uniqueTransporters}', boldStyle, normalStyle),
          _overviewItem('Vehicles', '${overview.uniqueVehicles}', boldStyle, normalStyle),
          _overviewItem('Total Loads', '${overview.totalLoads}', boldStyle, normalStyle),
          _overviewItem('Total Amount', '₹${overview.totalAmount.toStringAsFixed(0)}',
              boldStyle.copyWith(color: _accent), normalStyle),
          _overviewItem('Balance', '₹${overview.totalBalance.toStringAsFixed(0)}',
              boldStyle.copyWith(color: _successColor), normalStyle),
        ],
      ),
    );
  }

  static pw.Widget _overviewItem(
    String label,
    String value,
    pw.TextStyle valueStyle,
    pw.TextStyle labelStyle,
  ) {
    return pw.Column(
      children: [
        pw.Text(label, style: labelStyle.copyWith(color: _mutedText)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: valueStyle.copyWith(fontSize: 11)),
      ],
    );
  }

  // ─── Summary Table ───

  static pw.Widget _buildSummaryTable(
    ReportData data,
    pw.TextStyle headerStyle,
    pw.TextStyle cellStyle,
  ) {
    final isTransporter =
        data.config.viewMode == ReportViewMode.transporter;
    final groupLabel = isTransporter ? 'Transporter' : 'Vehicle No';

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FixedColumnWidth(45),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(65),
        4: const pw.FixedColumnWidth(55),
        5: const pw.FixedColumnWidth(55),
        6: const pw.FixedColumnWidth(65),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _tableHeaderCell(groupLabel, headerStyle),
            _tableHeaderCell('Trips', headerStyle),
            _tableHeaderCell('Loads', headerStyle),
            _tableHeaderCell('Amount', headerStyle),
            _tableHeaderCell('Diesel', headerStyle),
            _tableHeaderCell('Advance', headerStyle),
            _tableHeaderCell('Balance', headerStyle),
          ],
        ),
        // Data rows
        ...data.groups.map((group) => pw.TableRow(
              children: [
                _tableCell(group.groupKey, cellStyle,
                    align: pw.Alignment.centerLeft),
                _tableCell('${group.trips.length}', cellStyle),
                _tableCell('${group.totalLoads}', cellStyle),
                _tableCell(
                    '₹${group.totalAmount.toStringAsFixed(0)}', cellStyle),
                _tableCell(
                    '₹${group.dieselShare.toStringAsFixed(0)}', cellStyle),
                _tableCell(
                    '₹${group.advanceShare.toStringAsFixed(0)}', cellStyle),
                _tableCell('₹${group.balance.toStringAsFixed(0)}',
                    cellStyle.copyWith(color: _accent)),
              ],
            )),
        // Total row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _tableHeaderCell('Total', headerStyle),
            _tableHeaderCell('${data.overview.totalTrips}', headerStyle),
            _tableHeaderCell('${data.overview.totalLoads}', headerStyle),
            _tableHeaderCell(
                '₹${data.overview.totalAmount.toStringAsFixed(0)}',
                headerStyle.copyWith(color: _accent)),
            _tableHeaderCell(
                '₹${data.overview.totalDiesel.toStringAsFixed(0)}',
                headerStyle),
            _tableHeaderCell(
                '₹${data.overview.totalAdvance.toStringAsFixed(0)}',
                headerStyle),
            _tableHeaderCell(
                '₹${data.overview.totalBalance.toStringAsFixed(0)}',
                headerStyle.copyWith(color: _accent)),
          ],
        ),
      ],
    );
  }

  // ─── Group Detail Page ───

  static pw.Widget _buildGroupHeader(
    ReportGroup group,
    ReportConfig config,
    pw.TextStyle bold,
  ) {
    final typeLabel = config.viewMode == ReportViewMode.transporter
        ? 'Transporter'
        : 'Vehicle';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(typeLabel.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: _accent,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(group.groupKey,
                  style: bold.copyWith(fontSize: 16)),
            ],
          ),
          pw.Spacer(),
          pw.Text(
            DateFormatter.toRange(config.startDate, config.endDate),
            style: pw.TextStyle(fontSize: 9, color: _mutedText),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGroupTripTable(
    ReportGroup group,
    ReportConfig config,
    pw.TextStyle headerStyle,
    pw.TextStyle cellStyle,
  ) {
    final isTransporter =
        config.viewMode == ReportViewMode.transporter;
    // Show the "other" field: if grouped by transporter, show vehicle; vice versa
    final otherLabel = isTransporter ? 'Vehicle No' : 'Transporter';

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(65),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FixedColumnWidth(52),
        5: const pw.FixedColumnWidth(36),
        6: const pw.FixedColumnWidth(48),
        7: const pw.FixedColumnWidth(60),
        8: const pw.FixedColumnWidth(38),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _tableHeaderCell('#', headerStyle),
            _tableHeaderCell('Date', headerStyle),
            _tableHeaderCell('Location', headerStyle),
            _tableHeaderCell(otherLabel, headerStyle),
            _tableHeaderCell('Chainage', headerStyle),
            _tableHeaderCell('KM', headerStyle),
            _tableHeaderCell('Rate/KM', headerStyle),
            _tableHeaderCell('Amount', headerStyle),
            _tableHeaderCell('Loads', headerStyle),
          ],
        ),
        ...group.trips.asMap().entries.map((entry) {
          final i = entry.key;
          final trip = entry.value;
          final otherValue =
              isTransporter ? trip.vehicleNo : trip.transporter;

          return pw.TableRow(
            children: [
              _tableCell('${i + 1}', cellStyle),
              _tableCell(DateFormatter.toDisplay(trip.date), cellStyle),
              _tableCell(trip.location, cellStyle,
                  align: pw.Alignment.centerLeft),
              _tableCell(otherValue, cellStyle,
                  align: pw.Alignment.centerLeft),
              _tableCell(trip.chainage.toStringAsFixed(0), cellStyle),
              _tableCell(trip.km.toStringAsFixed(0), cellStyle),
              _tableCell(trip.ratePerKm.toStringAsFixed(0), cellStyle),
              _tableCell(trip.amountPerTrip.toStringAsFixed(0), cellStyle),
              _tableCell('${trip.noOfLoads}', cellStyle),
            ],
          );
        }),
        // Total row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableCell('', headerStyle),
            _tableHeaderCell(
              '₹${group.totalAmount.toStringAsFixed(0)}',
              headerStyle.copyWith(color: _accent),
            ),
            _tableHeaderCell(
              '${group.totalLoads}',
              headerStyle.copyWith(color: _accent),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildGroupFinancialFooter(
    ReportGroup group,
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
              pw.Text('Summary',
                  style: boldStyle.copyWith(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text('Trips: ${group.trips.length}',
                  style: normalStyle),
              pw.Text('Total Loads: ${group.totalLoads}',
                  style: normalStyle),
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
                    '₹${group.totalAmount.toStringAsFixed(0)}', normalStyle),
                pw.SizedBox(height: 6),
                _summaryRow('Diesel',
                    '- ₹${group.dieselShare.toStringAsFixed(0)}', mutedStyle),
                pw.SizedBox(height: 6),
                _summaryRow('Advance',
                    '- ₹${group.advanceShare.toStringAsFixed(0)}', mutedStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        top: pw.BorderSide(color: _borderColor, width: 0.5)),
                  ),
                  child: _summaryRow(
                    'Balance',
                    '₹${group.balance.toStringAsFixed(0)}',
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

  // ─── Table Helpers ───

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
