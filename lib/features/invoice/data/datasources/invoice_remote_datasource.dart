import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/utils/invoice_number_formatter.dart';
import 'package:vrs_transport_manager/features/invoice/data/models/invoice_record_model.dart';

class InvoiceRemoteDatasource {
  final FirebaseFirestore _firestore;

  InvoiceRemoteDatasource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('invoices');

  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _firestore.collection('app_config').doc('invoice_counter');

  Future<List<InvoiceRecordModel>> getInvoices() async {
    try {
      final snapshot =
          await _collection.orderBy('invoiceDate', descending: true).get();
      return snapshot.docs
          .map((doc) => InvoiceRecordModel.fromFirestore(doc))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load invoices: $e');
    }
  }

  Stream<List<InvoiceRecordModel>> watchInvoices() {
    return _collection
        .orderBy('invoiceDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceRecordModel.fromFirestore(doc))
            .toList());
  }

  Future<InvoiceRecordModel> getInvoiceById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw ServerException('Invoice not found');
      }
      return InvoiceRecordModel.fromFirestore(doc);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load invoice: $e');
    }
  }

  Future<String> createInvoice(InvoiceRecordModel model) async {
    try {
      final doc = await _collection.add(model.toFirestore());
      return doc.id;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create invoice: $e');
    }
  }

  Future<void> updateInvoice(InvoiceRecordModel model) async {
    try {
      await _collection.doc(model.id).update(model.toFirestore());
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update invoice: $e');
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _collection.doc(id).delete();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete invoice: $e');
    }
  }

  Future<List<InvoiceRecordModel>> searchInvoices(String query) async {
    try {
      final allInvoices = await getInvoices();
      if (query.isEmpty) return allInvoices;

      final lower = query.toLowerCase();
      return allInvoices.where((invoice) {
        return invoice.invoiceNumber.toLowerCase().contains(lower) ||
            invoice.client.companyName.toLowerCase().contains(lower);
      }).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to search invoices: $e');
    }
  }

  /// Previews the next invoice number without incrementing the counter.
  Future<String> previewNextInvoiceNumber(DateTime date) async {
    try {
      final key = InvoiceNumberFormatter.counterKey(date);

      final counterSnap = await _counterDoc.get();
      final counters =
          (counterSnap.data() ?? {}).cast<String, dynamic>();
      final lastSerial = (counters[key] as num?)?.toInt() ?? 0;
      final nextSerial = lastSerial + 1;

      return InvoiceNumberFormatter.format(date: date, serial: nextSerial);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to preview invoice number: $e');
    }
  }

  /// Increments the counter and returns the next invoice number.
  Future<String> commitInvoiceNumber(DateTime date) async {
    try {
      final key = InvoiceNumberFormatter.counterKey(date);

      final counterSnap = await _counterDoc.get();
      final counters =
          (counterSnap.data() ?? {}).cast<String, dynamic>();
      final lastSerial = (counters[key] as num?)?.toInt() ?? 0;
      final nextSerial = lastSerial + 1;

      // Update counter only on commit
      await _counterDoc.set({key: nextSerial}, SetOptions(merge: true));

      return InvoiceNumberFormatter.format(date: date, serial: nextSerial);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to generate invoice number: $e');
    }
  }
}
