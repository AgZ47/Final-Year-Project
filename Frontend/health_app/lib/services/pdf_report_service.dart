import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'health_database_service.dart';
import 'wellness_engine.dart';

class PdfReportService {
  static Future<Uint8List> generateHealthReport(
    PdfPageFormat format, {
    required String patientName,
    required String doctorName,
    required String appointmentDate,
  }) async {
    final pdf = pw.Document();
    final db = HealthDatabaseService.instance;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // 1. Aggregate Physical Data
    final stepsData = await db.getRecords('step_logs');
    int totalSteps = 0, stepLogsCount = 0;
    double totalCalories = 0;
    for (var s in stepsData) {
      final dt = DateTime.parse(s['timestamp'].toString());
      if (dt.isAfter(sevenDaysAgo)) {
        totalSteps += (s['steps'] as int);
        totalCalories += (s['calories_burned'] as num).toDouble();
        stepLogsCount++;
      }
    }
    final avgSteps = stepLogsCount > 0
        ? (totalSteps / stepLogsCount).round()
        : 0;
    final avgCal = stepLogsCount > 0
        ? (totalCalories / stepLogsCount).round()
        : 0;

    // 2. Aggregate Mental Health Data
    final moodData = await db.getRecords('mental_health_logs');
    int totalStress = 0, totalMood = 0, moodLogsCount = 0;

    // ⚡ Default text that gets overwritten if test data is found
    String ghqText = 'Pending wearable sync';
    String mdqText = 'Scheduled for next check-in';

    for (var m in moodData) {
      final dt = DateTime.parse(m['timestamp'].toString());
      if (dt.isAfter(sevenDaysAgo)) {
        totalStress += (m['stress_level'] as int);
        totalMood += (m['mood_score'] as int);
        moodLogsCount++;

        // ⚡ Check the notes field for the exact questionnaire scores
        final notes = m['journal_entry']?.toString() ?? '';
        if (notes.startsWith('GHQ Score:')) {
          ghqText = 'Completed - $notes';
        } else if (notes.startsWith('MDQ Score:')) {
          mdqText = 'Completed - $notes';
        }
      }
    }
    final avgStress = moodLogsCount > 0
        ? (totalStress / moodLogsCount).round()
        : 0;
    final avgMoodIndex = moodLogsCount > 0
        ? (totalMood / moodLogsCount).round()
        : -1;

    String moodLabel = 'Insufficient Data';
    if (avgMoodIndex >= 0) {
      const moodLabels = ['Happy', 'Calm', 'Neutral', 'Stressed', 'Sad'];
      moodLabel = avgMoodIndex < moodLabels.length
          ? moodLabels[avgMoodIndex]
          : 'Unknown';
    }

    // 3. Aggregate Sleep Data
    final sleepData = await db.getRecords('sleep_logs');
    int totalDeepSleep = 0, sleepLogsCount = 0, totalSleepScore = 0;
    for (var sl in sleepData) {
      final dt = DateTime.parse(sl['timestamp'].toString());
      if (dt.isAfter(sevenDaysAgo)) {
        totalDeepSleep += (sl['deep_sleep_minutes'] as int);
        totalSleepScore += (sl['sleep_quality'] as int);
        sleepLogsCount++;
      }
    }
    final avgDeepSleep = sleepLogsCount > 0
        ? (totalDeepSleep / sleepLogsCount).round()
        : 0;
    final avgSleepScore = sleepLogsCount > 0
        ? (totalSleepScore / sleepLogsCount).round()
        : 0;

    final insights = WellnessEngine.getInsights();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Aura Fit Health Summary',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${now.day}/${now.month}/${now.year}',
                      style: const pw.TextStyle(color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red800),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'CLINICAL PREVIEW',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.red800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient: $patientName',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Report Window: Last 7 Days'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Prepared For: $doctorName',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Appt: $appointmentDate'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            // ─── Wearable Screenings (GHQ / MDQ) ───
            _buildSectionTitle('Standardized Assessments (Wearable)'),
            pw.Text(
              'Self-reported questionnaires administered via Aura Fit Wearable sync.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 6),

            // ⚡ These now print "Completed - GHQ Score: X/12"
            pw.Bullet(text: 'GHQ-12 (General Health Questionnaire): $ghqText'),
            pw.Bullet(text: 'MDQ (Mood Disorder Questionnaire): $mdqText'),

            pw.SizedBox(height: 15),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Physical Health'),
                      _dataRow('Avg Daily Steps', '$avgSteps'),
                      _dataRow('Avg Calories', '$avgCal kcal'),
                      _dataRow('Active Days', '$stepLogsCount / 7'),
                      pw.SizedBox(height: 15),

                      _buildSectionTitle('Sleep Quality'),
                      _dataRow('Avg Sleep Score', '$avgSleepScore / 100'),
                      _dataRow('Avg Deep Sleep', '$avgDeepSleep mins'),
                      _dataRow('Nights Logged', '$sleepLogsCount / 7'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),

                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Mental & Emotional'),
                      _dataRow('Avg Stress Level', '$avgStress / 100'),
                      _dataRow('Predominant Mood', moodLabel),
                      _dataRow('Mood Logs', '$moodLogsCount / 7'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            _buildSectionTitle('AI-Detected Clinical Correlations'),
            pw.Text(
              'The Aura Fit engine has identified the following behavioral patterns over the reporting period:',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 8),
            ...insights.map(
              (i) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '• ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.Expanded(child: pw.Text('${i.title}: ${i.description}')),
                  ],
                ),
              ),
            ),

            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'This report is automatically generated by Aura Fit from locally stored device data. It is intended to assist healthcare professionals with generalized patient wellness tracking and does not constitute a clinical diagnosis.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _dataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
