import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/pdf_report_service.dart';

class PdfPreviewPage extends StatelessWidget {
  final String doctorName;
  final String patientName;
  final String appointmentDetails;

  const PdfPreviewPage({
    super.key,
    required this.doctorName,
    required this.patientName,
    required this.appointmentDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Health Report Preview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) => PdfReportService.generateHealthReport(
          format,
          patientName: patientName,
          doctorName: doctorName,
          appointmentDate: appointmentDetails,
        ),
        // Customize the preview UI colors to match your app
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
          ],
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
