import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_section.dart';

class InvoiceRecordModel extends InvoiceRecord {
  const InvoiceRecordModel({
    super.id,
    required super.invoiceNumber,
    required super.invoiceDate,
    required super.client,
    required super.sections,
    required super.totalValue,
    required super.cgstPercent,
    required super.sgstPercent,
    required super.igstPercent,
    required super.cgstAmount,
    required super.sgstAmount,
    required super.igstAmount,
    required super.subTotal,
    required super.tdsPercent,
    required super.retentionPercent,
    required super.tdsAmount,
    required super.retentionAmount,
    required super.totalInvoiceValue,
    required super.amountInWords,
    super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  factory InvoiceRecordModel.fromEntity(InvoiceRecord entity) {
    return InvoiceRecordModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      invoiceDate: entity.invoiceDate,
      client: entity.client,
      sections: entity.sections,
      totalValue: entity.totalValue,
      cgstPercent: entity.cgstPercent,
      sgstPercent: entity.sgstPercent,
      igstPercent: entity.igstPercent,
      cgstAmount: entity.cgstAmount,
      sgstAmount: entity.sgstAmount,
      igstAmount: entity.igstAmount,
      subTotal: entity.subTotal,
      tdsPercent: entity.tdsPercent,
      retentionPercent: entity.retentionPercent,
      tdsAmount: entity.tdsAmount,
      retentionAmount: entity.retentionAmount,
      totalInvoiceValue: entity.totalInvoiceValue,
      amountInWords: entity.amountInWords,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  factory InvoiceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final clientData = data['client'] as Map<String, dynamic>? ?? {};
    final client = Client.fromMap(clientData);

    final sectionsData = data['sections'] as List<dynamic>? ?? [];
    final sections = sectionsData
        .map((s) => InvoiceSection.fromMap(s as Map<String, dynamic>))
        .toList();

    return InvoiceRecordModel(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      invoiceDate: (data['invoiceDate'] as Timestamp).toDate(),
      client: client,
      sections: sections,
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0,
      cgstPercent: (data['cgstPercent'] as num?)?.toDouble() ?? 0,
      sgstPercent: (data['sgstPercent'] as num?)?.toDouble() ?? 0,
      igstPercent: (data['igstPercent'] as num?)?.toDouble() ?? 0,
      cgstAmount: (data['cgstAmount'] as num?)?.toDouble() ?? 0,
      sgstAmount: (data['sgstAmount'] as num?)?.toDouble() ?? 0,
      igstAmount: (data['igstAmount'] as num?)?.toDouble() ?? 0,
      subTotal: (data['subTotal'] as num?)?.toDouble() ?? 0,
      tdsPercent: (data['tdsPercent'] as num?)?.toDouble() ?? 0,
      retentionPercent: (data['retentionPercent'] as num?)?.toDouble() ?? 0,
      tdsAmount: (data['tdsAmount'] as num?)?.toDouble() ?? 0,
      retentionAmount: (data['retentionAmount'] as num?)?.toDouble() ?? 0,
      totalInvoiceValue:
          (data['totalInvoiceValue'] as num?)?.toDouble() ?? 0,
      amountInWords: data['amountInWords'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'client': client.toMap(),
      'sections': sections.map((s) => s.toMap()).toList(),
      'totalValue': totalValue,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'igstPercent': igstPercent,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'subTotal': subTotal,
      'tdsPercent': tdsPercent,
      'retentionPercent': retentionPercent,
      'tdsAmount': tdsAmount,
      'retentionAmount': retentionAmount,
      'totalInvoiceValue': totalInvoiceValue,
      'amountInWords': amountInWords,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
