import 'package:equatable/equatable.dart';
import 'invoice_line_item.dart';

class InvoiceSection extends Equatable {
  final String header;
  final List<InvoiceLineItem> lineItems;

  const InvoiceSection({
    required this.header,
    required this.lineItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'header': header,
      'lineItems': lineItems.map((i) => i.toMap()).toList(),
    };
  }

  factory InvoiceSection.fromMap(Map<String, dynamic> map) {
    return InvoiceSection(
      header: map['header'] as String? ?? '',
      lineItems: (map['lineItems'] as List<dynamic>?)
              ?.map((i) => InvoiceLineItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object> get props => [header, lineItems];
}
