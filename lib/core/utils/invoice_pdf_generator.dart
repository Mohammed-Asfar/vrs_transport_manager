import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';

final _inr = NumberFormat('#,##,###.##', 'en_IN');

class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  static const _dark = PdfColors.grey900;
  static const _muted = PdfColors.grey600;
  static const _border = PdfColors.grey400;
  static const _headerBg = PdfColor.fromInt(0xFFF2F2F7);
  static const _lightBg = PdfColor.fromInt(0xFFFAFAFA);

  static Future<void> generateAndPrint(
    InvoiceRecord invoice,
    CompanyProfile? profile,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bold = pw.TextStyle(font: fontBold, fontFallback: [font]);
    final normal = pw.TextStyle(font: font, fontFallback: [font]);
    final s9 = normal.copyWith(fontSize: 9, color: _dark);
    final s9b = bold.copyWith(fontSize: 9, color: _dark);
    final s8 = normal.copyWith(fontSize: 8, color: _dark);
    final s8b = bold.copyWith(fontSize: 8, color: _dark);
    final s8m = normal.copyWith(fontSize: 8, color: _muted);

    // Decode logo/signature if available
    pw.MemoryImage? logoImage;
    pw.MemoryImage? signatureImage;
    if (profile?.logoBase64 != null && profile!.logoBase64!.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(profile.logoBase64!));
      } catch (_) {}
    }
    if (profile?.signatureBase64 != null &&
        profile!.signatureBase64!.isNotEmpty) {
      try {
        signatureImage =
            pw.MemoryImage(base64Decode(profile.signatureBase64!));
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Company header
            _buildCompanyHeader(profile, logoImage, bold, s9, s8m),
            pw.SizedBox(height: 8),

            // Invoice number + date
            _buildInvoiceMeta(invoice, s9b, s9),
            pw.SizedBox(height: 12),

            // Billed To
            _buildBilledTo(invoice, s9b, s9, s8m),
            pw.SizedBox(height: 14),

            // Line items table (with sections)
            _buildLineItemsTable(invoice, s8b, s8, s8m),
            pw.SizedBox(height: 4),

            // Tax + Sub Total
            _buildTaxBreakdown(invoice, s9b, s9),
            pw.SizedBox(height: 4),

            // Recoveries
            _buildRecoveries(invoice, s9b, s9),
            pw.SizedBox(height: 4),

            // Total Invoice Value
            _buildTotalInvoiceValue(invoice, bold, s9),
            pw.SizedBox(height: 16),

            // Amount in words
            _buildAmountInWords(invoice, s9, s9b),
            pw.SizedBox(height: 20),

            // Bank details + Signature
            _buildFooter(profile, signatureImage, s9b, s9, s8m),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name:
          'VRS_Invoice_${invoice.invoiceNumber}_${DateFormatter.toDisplay(invoice.invoiceDate)}',
    );
  }

  static pw.Widget _buildCompanyHeader(
    CompanyProfile? profile,
    pw.MemoryImage? logo,
    pw.TextStyle bold,
    pw.TextStyle normal,
    pw.TextStyle muted,
  ) {
    final name = profile?.companyName ?? 'VRS ENTERPRISES';
    final gstin = profile?.gstin ?? '';
    final phone1 = profile?.phone1 ?? '';
    final phone2 = profile?.phone2 ?? '';
    final email = profile?.email ?? '';
    final address = profile?.address ?? '';
    final tagline = profile?.tagline ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: GSTIN
          if (gstin.isNotEmpty)
            pw.Text('GSTIN: $gstin', style: muted),
          pw.Spacer(),
          // Center: Logo + company name
          pw.Column(
            children: [
              if (logo != null)
                pw.Image(logo, width: 50, height: 50),
              pw.SizedBox(height: 4),
              pw.Text(name.toUpperCase(),
                  style: bold.copyWith(fontSize: 16, letterSpacing: 1)),
              if (tagline.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _border, width: 0.5),
                  ),
                  child: pw.Text(tagline, style: muted.copyWith(fontSize: 7)),
                ),
              ],
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(address,
                    style: muted.copyWith(fontSize: 7),
                    textAlign: pw.TextAlign.center),
              ],
            ],
          ),
          pw.Spacer(),
          // Right: Contact
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (phone1.isNotEmpty) pw.Text(phone1, style: normal),
              if (phone2.isNotEmpty) pw.Text(phone2, style: normal),
              if (email.isNotEmpty) pw.Text(email, style: muted),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceMeta(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
  ) {
    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Spacer(),
          pw.Column(
            children: [
              pw.Text('TAX INVOICE',
                  style: bold.copyWith(fontSize: 12, letterSpacing: 1)),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Invoice No: ${invoice.invoiceNumber}', style: bold),
              pw.SizedBox(height: 2),
              pw.Text(
                  'Invoice Date: ${DateFormatter.toDisplay(invoice.invoiceDate)}',
                  style: normal),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBilledTo(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
    pw.TextStyle muted,
  ) {
    final client = invoice.client;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Billed To:', style: muted),
          pw.SizedBox(height: 4),
          pw.Text(client.companyName, style: bold),
          if (client.gstin.isNotEmpty)
            pw.Text('GSTIN: ${client.gstin}', style: normal),
          if (client.address.isNotEmpty)
            pw.Text(client.address, style: normal),
        ],
      ),
    );
  }

  static pw.Widget _buildLineItemsTable(
    InvoiceRecord invoice,
    pw.TextStyle headerStyle,
    pw.TextStyle cellStyle,
    pw.TextStyle mutedStyle,
  ) {
    final rows = <pw.TableRow>[];

    // Header row
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: _headerBg),
      children: [
        _hCell('SL.\nNO', headerStyle),
        _hCell('SAC\nCODE', headerStyle),
        _hCell('DESCRIPTION', headerStyle, align: pw.Alignment.centerLeft),
        _hCell('UNIT', headerStyle),
        _hCell('QTY', headerStyle),
        _hCell('RATE', headerStyle),
        _hCell('TOTAL\nAMOUNT', headerStyle),
      ],
    ));

    int globalSl = 0;
    for (final section in invoice.sections) {
      // Section header row
      if (section.header.isNotEmpty) {
        rows.add(pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightBg),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 5),
              child: pw.Text('', style: cellStyle),
            ),
            pw.Container(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 5),
              child: pw.Text('${section.header}:-',
                  style: headerStyle),
            ),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
          ],
        ));
      }

      // Line item rows
      for (final item in section.lineItems) {
        globalSl++;
        rows.add(pw.TableRow(
          children: [
            _cell('$globalSl', cellStyle),
            _cell(item.sacCode, cellStyle),
            _cell(item.description, cellStyle,
                align: pw.Alignment.centerLeft),
            _cell(item.unit, cellStyle),
            _cell(item.qty.toStringAsFixed(1), cellStyle),
            _cell(item.rate.toStringAsFixed(2), cellStyle),
            _cell(_inr.format(item.totalAmount), cellStyle),
          ],
        ));
      }
    }

    // Total Value row
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: _headerBg),
      children: [
        _cell('', headerStyle),
        _cell('', headerStyle),
        _cell('', headerStyle),
        _cell('', headerStyle),
        _cell('', headerStyle),
        _hCell('Total Value', headerStyle),
        _hCell(_inr.format(invoice.totalValue), headerStyle),
      ],
    ));

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(48),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(55),
        5: const pw.FixedColumnWidth(50),
        6: const pw.FixedColumnWidth(72),
      },
      children: rows,
    );
  }

  static pw.Widget _buildTaxBreakdown(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
  ) {
    return pw.Container(
      child: pw.Column(
        children: [
          if (invoice.cgstPercent > 0)
            _rightAlignedRow(
                'CGST @ ${invoice.cgstPercent.toStringAsFixed(0)}%',
                _inr.format(invoice.cgstAmount),
                normal),
          if (invoice.sgstPercent > 0)
            _rightAlignedRow(
                'SGST @ ${invoice.sgstPercent.toStringAsFixed(0)}%',
                _inr.format(invoice.sgstAmount),
                normal),
          if (invoice.igstPercent > 0)
            _rightAlignedRow(
                'IGST @ ${invoice.igstPercent.toStringAsFixed(0)}%',
                _inr.format(invoice.igstAmount),
                normal),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border:
                  pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
            ),
            child: _rightAlignedRow(
                'Sub Total', _inr.format(invoice.subTotal), bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRecoveries(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
  ) {
    if (invoice.tdsPercent == 0 && invoice.retentionPercent == 0) {
      return pw.SizedBox();
    }

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Recoveries', style: bold),
          if (invoice.tdsPercent > 0)
            _rightAlignedRow(
                'TDS @ ${invoice.tdsPercent.toStringAsFixed(0)}%',
                _inr.format(invoice.tdsAmount),
                normal),
          if (invoice.retentionPercent > 0)
            _rightAlignedRow(
                'Retention Money @ ${invoice.retentionPercent.toStringAsFixed(0)}%',
                _inr.format(invoice.retentionAmount),
                normal),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalInvoiceValue(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _border, width: 1),
          bottom: pw.BorderSide(color: _border, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total Invoice Value',
              style: bold.copyWith(fontSize: 11)),
          pw.Text(_inr.format(invoice.totalInvoiceValue),
              style: bold.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildAmountInWords(
    InvoiceRecord invoice,
    pw.TextStyle normal,
    pw.TextStyle bold,
  ) {
    return pw.Row(
      children: [
        pw.Text('In Words: ', style: bold),
        pw.Text(invoice.amountInWords, style: normal),
      ],
    );
  }

  static pw.Widget _buildFooter(
    CompanyProfile? profile,
    pw.MemoryImage? signature,
    pw.TextStyle bold,
    pw.TextStyle normal,
    pw.TextStyle muted,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bank details
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Please remit the Payment to:', style: muted),
                pw.SizedBox(height: 4),
                if (profile != null) ...[
                  pw.Text(
                      'NAME: M/S ${profile.companyName}', style: normal),
                  pw.Text('ACC NO: ${profile.accountNo}', style: normal),
                  pw.Text('BANK: ${profile.bankName}', style: normal),
                  pw.Text('BRANCH: ${profile.bankBranch}', style: normal),
                  pw.Text('IFS CODE: ${profile.ifscCode}', style: normal),
                ] else
                  pw.Text('Bank details not configured', style: muted),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 40),
        // Signature
        pw.SizedBox(
          width: 160,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'For ${profile?.companyName ?? "M/S VRS Enterprises"}',
                style: bold,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              if (signature != null)
                pw.Image(signature, width: 100, height: 50,
                    fit: pw.BoxFit.contain)
              else
                pw.SizedBox(height: 50),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      top: pw.BorderSide(color: _border, width: 0.5)),
                ),
                child: pw.Text('Authorized Signatory', style: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Table helpers ──

  static pw.Widget _hCell(String text, pw.TextStyle style,
      {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: align,
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(String text, pw.TextStyle style,
      {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _rightAlignedRow(
      String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label, style: style),
                pw.Text(value, style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
