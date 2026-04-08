import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/core/utils/number_to_words.dart';
import 'client.dart';
import 'invoice_section.dart';

class InvoiceRecord extends Equatable {
  final String? id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final Client client;
  final List<InvoiceSection> sections;
  final double totalValue;
  final double cgstPercent;
  final double sgstPercent;
  final double igstPercent;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double subTotal;
  final double tdsPercent;
  final double retentionPercent;
  final double tdsAmount;
  final double retentionAmount;
  final double totalInvoiceValue;
  final String amountInWords;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const InvoiceRecord({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.client,
    required this.sections,
    required this.totalValue,
    required this.cgstPercent,
    required this.sgstPercent,
    required this.igstPercent,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.subTotal,
    required this.tdsPercent,
    required this.retentionPercent,
    required this.tdsAmount,
    required this.retentionAmount,
    required this.totalInvoiceValue,
    required this.amountInWords,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Auto-calculate all computed fields from sections and tax/recovery percentages
  factory InvoiceRecord.create({
    String? id,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required Client client,
    required List<InvoiceSection> sections,
    double cgstPercent = 0,
    double sgstPercent = 0,
    double igstPercent = 0,
    double tdsPercent = 0,
    double retentionPercent = 0,
    String? createdBy,
  }) {
    final totalValue = sections.fold<double>(
      0,
      (sum, section) => sum + section.lineItems.fold<double>(
        0,
        (sectionSum, item) => sectionSum + item.totalAmount,
      ),
    );

    final cgstAmount = totalValue * cgstPercent / 100;
    final sgstAmount = totalValue * sgstPercent / 100;
    final igstAmount = totalValue * igstPercent / 100;
    final subTotal = totalValue + cgstAmount + sgstAmount + igstAmount;
    final tdsAmount = subTotal * tdsPercent / 100;
    final retentionAmount = subTotal * retentionPercent / 100;
    final totalInvoiceValue = subTotal - tdsAmount - retentionAmount;
    final amountInWords = NumberToWords.convert(totalInvoiceValue);

    return InvoiceRecord(
      id: id,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      client: client,
      sections: sections,
      totalValue: totalValue,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      igstPercent: igstPercent,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      subTotal: subTotal,
      tdsPercent: tdsPercent,
      retentionPercent: retentionPercent,
      tdsAmount: tdsAmount,
      retentionAmount: retentionAmount,
      totalInvoiceValue: totalInvoiceValue,
      amountInWords: amountInWords,
      createdBy: createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        invoiceDate,
        client,
        sections,
        totalValue,
        cgstPercent,
        sgstPercent,
        igstPercent,
        cgstAmount,
        sgstAmount,
        igstAmount,
        subTotal,
        tdsPercent,
        retentionPercent,
        tdsAmount,
        retentionAmount,
        totalInvoiceValue,
        amountInWords,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
