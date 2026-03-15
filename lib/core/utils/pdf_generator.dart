import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';

class PdfGenerator {
  PdfGenerator._();

  static Future<void> generateAndPrint(TransportRecord record) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'VRS ENTERPRISES',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      record.location.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Trip Details Table
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(70),
                  3: const pw.FixedColumnWidth(55),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(60),
                  6: const pw.FixedColumnWidth(80),
                  7: const pw.FixedColumnWidth(60),
                },
                headers: [
                  'S.no',
                  'Vehicle no',
                  'Transporter',
                  'Chainage',
                  'KM',
                  'Rate Per Km',
                  'Amount per trip',
                  'No of Loads',
                ],
                data: [
                  ...record.trips.map((trip) => [
                        '${trip.sNo}',
                        trip.vehicleNo,
                        trip.transporter,
                        trip.chainage.toStringAsFixed(0),
                        trip.km.toStringAsFixed(0),
                        trip.ratePerKm.toStringAsFixed(0),
                        trip.amountPerTrip.toStringAsFixed(0),
                        '${trip.noOfLoads}',
                      ]),
                  // Total row
                  [
                    '',
                    '',
                    '',
                    '',
                    '',
                    '',
                    'Total',
                    '${record.totalLoads}',
                  ],
                ],
              ),
              pw.SizedBox(height: 32),

              // Financial Summary
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Spacer(),
                  pw.SizedBox(
                    width: 250,
                    child: pw.Column(
                      children: [
                        // Date
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Date',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text(DateFormatter.toDisplay(record.date),
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 8),

                        // Amount table header
                        pw.TableHelper.fromTextArray(
                          context: context,
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          cellStyle: const pw.TextStyle(fontSize: 10),
                          headerDecoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          cellAlignment: pw.Alignment.center,
                          headerAlignment: pw.Alignment.center,
                          headers: ['Amount', 'Diesel', 'Balance'],
                          data: [
                            ...record.trips.map((trip) {
                              final tripTotal = trip.amountPerTrip * trip.noOfLoads;
                              return [
                                tripTotal.toStringAsFixed(0),
                                '',
                                tripTotal.toStringAsFixed(0),
                              ];
                            }),
                            // Total row
                            [
                              record.totalAmount.toStringAsFixed(0),
                              record.diesel.toStringAsFixed(0),
                              record.totalAmount.toStringAsFixed(0),
                            ],
                          ],
                        ),

                        pw.SizedBox(height: 12),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Advance', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(record.advance.toStringAsFixed(0),
                                style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Balance',
                                style:
                                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text(record.balance.toStringAsFixed(0),
                                style:
                                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
}
