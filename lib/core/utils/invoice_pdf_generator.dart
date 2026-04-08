import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';

final _inr = NumberFormat('₹#,##,###.##', 'en_IN');

class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  static const _dark = PdfColors.grey900;
  static const _muted = PdfColors.grey600;
  static const _border = PdfColors.grey400;
  static const _headerBg = PdfColor.fromInt(0xFFF0F0F0);

  static Future<void> generateAndPrint(
    InvoiceRecord invoice,
    CompanyProfile? profile,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bold = pw.TextStyle(
      font: fontBold,
      fontSize: 8,
      color: _dark,
      fontFallback: [font],
    );
    final normal = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: _dark,
      fontFallback: [font],
    );

    // Font styles - compact for single page
    final s8 = normal;
    final s8b = bold;
    final s7 = normal.copyWith(fontSize: 7);
    final s7b = bold.copyWith(fontSize: 7);
    final s7m = normal.copyWith(fontSize: 7, color: _muted);

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
        signatureImage = pw.MemoryImage(base64Decode(profile.signatureBase64!));
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company header
              _buildCompanyHeader(profile, logoImage, bold, normal, s7m),
              pw.SizedBox(height: 8),

              // TAX INVOICE title + Invoice No/Date
              _buildTaxInvoiceRow(invoice, bold, s8, s8b),
              pw.SizedBox(height: 8),

              // Billed To
              _buildBilledTo(invoice, s8b, s8),
              pw.SizedBox(height: 8),

              // Main table (line items + tax + recoveries + total)
              _buildFullTable(invoice, s7b, s7, s8b, s8),

              // In Words
              pw.SizedBox(height: 6),
              _buildAmountInWords(invoice, s8, s8b),
              pw.SizedBox(height: 10),

              // Bank details + Signature
              _buildFooter(profile, signatureImage, s8b, s8, s7m),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'VRS_Invoice_${invoice.invoiceNumber}_${DateFormatter.toDisplay(invoice.invoiceDate)}.pdf',
    );
  }

  // ── Company Header ──

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
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: GSTIN
          pw.SizedBox(
            width: 130,
            child: gstin.isNotEmpty
                ? pw.Text('GSTIN: $gstin', style: normal.copyWith(fontSize: 7))
                : pw.SizedBox(),
          ),
          pw.Spacer(),
          // Center: Logo + company name + tagline + address
          pw.Column(
            children: [
              if (logo != null) ...[
                pw.Image(logo, fit: pw.BoxFit.fitWidth, width: 100, height: 40),
                pw.SizedBox(height: 3),
              ],
              pw.Text(
                name.toUpperCase(),
                style: bold.copyWith(fontSize: 18, letterSpacing: 1),
              ),
              if (tagline.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _border, width: 0.5),
                  ),
                  child: pw.Text(tagline, style: normal.copyWith(fontSize: 7)),
                ),
              ],
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  address,
                  style: normal.copyWith(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
          pw.Spacer(),
          // Right: Contact info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (phone1.isNotEmpty)
                pw.Text(phone1, style: bold.copyWith(fontSize: 9)),
              if (phone2.isNotEmpty)
                pw.Text(phone2, style: normal.copyWith(fontSize: 8)),
              if (email.isNotEmpty)
                pw.Text('Email: $email', style: normal.copyWith(fontSize: 7)),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAX INVOICE + Invoice No/Date row ──

  static pw.Widget _buildTaxInvoiceRow(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
    pw.TextStyle normalBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Left spacer same width as right column to keep title centered
          pw.SizedBox(width: 160),
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                'TAX INVOICE',
                style: bold.copyWith(fontSize: 14, letterSpacing: 2),
              ),
            ),
          ),
          // Right: Invoice No / Date
          pw.SizedBox(
            width: 160,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Invoice No : ', style: normalBold),
                      pw.TextSpan(text: invoice.invoiceNumber, style: normal),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Invoice Date : ', style: normalBold),
                      pw.TextSpan(
                        text: DateFormatter.toDisplay(invoice.invoiceDate),
                        style: normal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Billed To ──

  static pw.Widget _buildBilledTo(
    InvoiceRecord invoice,
    pw.TextStyle bold,
    pw.TextStyle normal,
  ) {
    final client = invoice.client;
    return pw.Container(
      width: 280,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Billed To :', style: bold.copyWith(fontSize: 7)),
          pw.SizedBox(height: 3),
          pw.Text(client.companyName, style: bold.copyWith(fontSize: 9)),
          if (client.gstin.isNotEmpty)
            pw.Text('GSTIN : ${client.gstin}', style: normal),
          if (client.address.isNotEmpty) pw.Text(client.address, style: normal),
        ],
      ),
    );
  }

  // ── Full Table (line items + tax + recoveries + total) ──

  static const _columnWidths = <int, pw.TableColumnWidth>{
    0: pw.FixedColumnWidth(28),
    1: pw.FixedColumnWidth(46),
    2: pw.FlexColumnWidth(3),
    3: pw.FixedColumnWidth(38),
    4: pw.FixedColumnWidth(52),
    5: pw.FixedColumnWidth(55),
    6: pw.FixedColumnWidth(72),
  };

  static pw.Widget _buildFullTable(
    InvoiceRecord invoice,
    pw.TextStyle hStyle,
    pw.TextStyle cStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle normalStyle,
  ) {
    final widgets = <pw.Widget>[];
    var currentRows = <pw.TableRow>[];

    // Header row
    currentRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _headerBg),
        children: [
          _hCell('SL.\nNO', hStyle),
          _hCell('SAC\nCODE', hStyle),
          _hCell('DESCRIPTION', hStyle, align: pw.Alignment.centerLeft),
          _hCell('UNIT', hStyle),
          _hCell('QTY', hStyle),
          _hCell('RATE', hStyle),
          _hCell('TOTAL\nAMOUNT', hStyle),
        ],
      ),
    );

    // Sections + line items
    int slNo = 0;
    for (final section in invoice.sections) {
      // Section header — flush current rows, add borderless header, start new table
      if (section.header.isNotEmpty) {
        if (currentRows.isNotEmpty) {
          widgets.add(
            _buildTableChunk(currentRows, showTopBorder: widgets.isEmpty),
          );
          currentRows = <pw.TableRow>[];
        }
        widgets.add(
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: _border, width: 0.5),
                right: pw.BorderSide(color: _border, width: 0.5),
                bottom: pw.BorderSide(color: _border, width: 0.5),
              ),
            ),
            child: pw.Text('${section.header}:-', style: hStyle),
          ),
        );
      }

      for (final item in section.lineItems) {
        slNo++;
        currentRows.add(
          pw.TableRow(
            children: [
              _cell('$slNo', cStyle),
              _cell(item.sacCode, cStyle),
              _cell(item.description, cStyle, align: pw.Alignment.centerLeft),
              _cell(item.unit, cStyle),
              _cell(item.qty.toStringAsFixed(1), cStyle),
              _cell(item.rate.toStringAsFixed(2), cStyle),
              _cell(_inr.format(item.totalAmount), cStyle),
            ],
          ),
        );
      }
    }

    // Total Value row
    currentRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _headerBg),
        children: [
          _cell('', cStyle),
          _cell('', cStyle),
          _cell('', cStyle),
          _cell('', cStyle),
          _cell('', cStyle),
          _hCell('Total Value', hStyle),
          _hCell(_inr.format(invoice.totalValue), hStyle),
        ],
      ),
    );

    // CGST row
    if (invoice.cgstPercent > 0) {
      slNo++;
      currentRows.add(
        _taxRow(
          '',
          'CGST @ ${invoice.cgstPercent.toStringAsFixed(0)}%',
          _inr.format(invoice.cgstAmount),
          cStyle,
        ),
      );
    }

    // SGST row
    if (invoice.sgstPercent > 0) {
      slNo++;
      currentRows.add(
        _taxRow(
          '',
          'SGST @ ${invoice.sgstPercent.toStringAsFixed(0)}%',
          _inr.format(invoice.sgstAmount),
          cStyle,
        ),
      );
    }

    // IGST row
    if (invoice.igstPercent > 0) {
      slNo++;
      currentRows.add(
        _taxRow(
          '',
          'IGST @ ${invoice.igstPercent.toStringAsFixed(0)}%',
          _inr.format(invoice.igstAmount),
          cStyle,
        ),
      );
    }

    // Sub Total row
    final subTotalSlNo = slNo + 1;
    currentRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _headerBg),
        children: [
          _cell('$subTotalSlNo', hStyle),
          _cell('', hStyle),
          _cell('Sub Total', hStyle, align: pw.Alignment.centerLeft),
          _cell('', hStyle),
          _cell('', hStyle),
          _cell('', hStyle),
          _hCell(_inr.format(invoice.subTotal), hStyle),
        ],
      ),
    );

    // Recoveries section
    if (invoice.tdsPercent > 0 || invoice.retentionPercent > 0) {
      // Recoveries header — borderless row
      if (currentRows.isNotEmpty) {
        widgets.add(
          _buildTableChunk(currentRows, showTopBorder: widgets.isEmpty),
        );
        currentRows = <pw.TableRow>[];
      }
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _border, width: 0.5),
              right: pw.BorderSide(color: _border, width: 0.5),
              bottom: pw.BorderSide(color: _border, width: 0.5),
            ),
          ),
          child: pw.Text('Recoveries', style: hStyle),
        ),
      );

      int recoverySlNo = subTotalSlNo;

      if (invoice.tdsPercent > 0) {
        recoverySlNo++;
        currentRows.add(
          pw.TableRow(
            children: [
              _cell('$recoverySlNo', cStyle),
              _cell('', cStyle),
              _cell('TDS', cStyle, align: pw.Alignment.centerLeft),
              _cell('', cStyle),
              _cell('', cStyle),
              _cell('${invoice.tdsPercent.toStringAsFixed(0)}%', cStyle),
              _cell(_inr.format(invoice.tdsAmount), cStyle),
            ],
          ),
        );
      }

      if (invoice.retentionPercent > 0) {
        recoverySlNo++;
        currentRows.add(
          pw.TableRow(
            children: [
              _cell('$recoverySlNo', cStyle),
              _cell('', cStyle),
              _cell('Retention Money', cStyle, align: pw.Alignment.centerLeft),
              _cell('', cStyle),
              _cell('', cStyle),
              _cell('${invoice.retentionPercent.toStringAsFixed(0)}%', cStyle),
              _cell(_inr.format(invoice.retentionAmount), cStyle),
            ],
          ),
        );
      }
    }

    // Total Invoice Value row
    currentRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _headerBg),
        children: [
          _cell('', hStyle),
          _cell('', hStyle),
          _cell('', hStyle),
          _cell('', hStyle),
          _cell('', hStyle),
          _hCell('Total Invoice Value', hStyle),
          _hCell(_inr.format(invoice.totalInvoiceValue), hStyle),
        ],
      ),
    );

    // Flush remaining rows
    if (currentRows.isNotEmpty) {
      widgets.add(
        _buildTableChunk(currentRows, showTopBorder: widgets.isEmpty),
      );
    }

    return pw.Column(children: widgets);
  }

  static pw.Widget _buildTableChunk(
    List<pw.TableRow> rows, {
    bool showTopBorder = true,
  }) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(color: _border, width: 0.5),
        right: const pw.BorderSide(color: _border, width: 0.5),
        bottom: const pw.BorderSide(color: _border, width: 0.5),
        top: showTopBorder
            ? const pw.BorderSide(color: _border, width: 0.5)
            : pw.BorderSide.none,
        horizontalInside: const pw.BorderSide(color: _border, width: 0.5),
        verticalInside: const pw.BorderSide(color: _border, width: 0.5),
      ),
      columnWidths: _columnWidths,
      children: rows,
    );
  }

  // ── Amount in Words ──

  static pw.Widget _buildAmountInWords(
    InvoiceRecord invoice,
    pw.TextStyle normal,
    pw.TextStyle bold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: 'In Words : ', style: bold),
            pw.TextSpan(text: invoice.amountInWords, style: normal),
          ],
        ),
      ),
    );
  }

  // ── Footer: Bank + Signature ──

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
                pw.Text('Bank Details :', style: bold.copyWith(fontSize: 8)),
                pw.SizedBox(height: 4),
                if (profile != null) ...[
                  pw.Text('NAME : M/S ${profile.companyName}', style: bold),
                  pw.SizedBox(height: 1),
                  pw.Text('ACC NO : ${profile.accountNo}', style: normal),
                  pw.Text('BANK : ${profile.bankName}', style: normal),
                  pw.Text('BRANCH : ${profile.bankBranch}', style: normal),
                  pw.Text('IFS CODE : ${profile.ifscCode}', style: bold),
                ] else
                  pw.Text('Bank details not configured', style: muted),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 30),
        // Signature
        pw.SizedBox(
          width: 160,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'For M/S ${profile?.companyName ?? "VRS Enterprises"}',
                style: bold.copyWith(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              if (signature != null)
                pw.Image(
                  signature,
                  width: 100,
                  height: 45,
                  fit: pw.BoxFit.contain,
                )
              else
                pw.SizedBox(height: 45),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: _border, width: 0.5),
                  ),
                ),
                child: pw.Text(
                  'Authorized Signatory',
                  style: muted.copyWith(fontSize: 7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Table helpers ──

  static pw.Widget _hCell(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: align,
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  static pw.TableRow _taxRow(
    String slNo,
    String label,
    String amount,
    pw.TextStyle style,
  ) {
    return pw.TableRow(
      children: [
        _cell(slNo, style),
        _cell('', style),
        _cell('', style),
        _cell('', style),
        _cell('', style),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(label, style: style),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          alignment: pw.Alignment.center,
          child: pw.Text(amount, style: style),
        ),
      ],
    );
  }
}
