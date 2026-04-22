class FirestoreConstants {
  FirestoreConstants._();

  // Collections
  static const String transportRecords = 'transport_records';

  // Transport Record Fields
  static const String date = 'date';
  static const String location = 'location';
  static const String transporter = 'transporter';
  static const String trips = 'trips';
  static const String totalLoads = 'totalLoads';
  static const String totalAmount = 'totalAmount';
  static const String diesel = 'diesel';
  static const String advance = 'advance';
  static const String balance = 'balance';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String createdBy = 'createdBy';

  // Trip Entry Fields
  static const String sNo = 'sNo';
  static const String vehicleNo = 'vehicleNo';
  static const String chainage = 'chainage';
  static const String km = 'km';
  static const String ratePerKm = 'ratePerKm';
  static const String amountPerTrip = 'amountPerTrip';
  static const String noOfLoads = 'noOfLoads';

  // Machinery Collection
  static const String machineryRecords = 'machinery_records';

  // Client Collection
  static const String clients = 'clients';
  static const String companyName = 'companyName';
  static const String gstin = 'gstin';
  static const String address = 'address';

  // Invoice Collection
  static const String invoices = 'invoices';
  static const String invoiceNumber = 'invoiceNumber';
  static const String invoiceDate = 'invoiceDate';
  static const String invoiceCounter = 'invoice_counter';

  // Company Profile Collection
  static const String companyProfile = 'company_profile';
  static const String companyProfileDoc = 'profile';

  // Payment Collection
  static const String payments = 'payments';

  // Payment Fields
  static const String transporterName = 'transporterName';
  static const String amount = 'amount';
  static const String paymentDate = 'paymentDate';
  static const String weekStartDate = 'weekStartDate';
  static const String weekEndDate = 'weekEndDate';

  // Machinery Record Fields
  static const String machineName = 'machineName';
  static const String machineNumber = 'machineNumber';
  static const String operatorName = 'operatorName';
  static const String billingMode = 'billingMode';
  static const String monthlyRent = 'monthlyRent';
  static const String ratePerLoad = 'ratePerLoad';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String remarks = 'remarks';
}
