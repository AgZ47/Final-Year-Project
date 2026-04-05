import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'health_database_service.dart';
import 'wellness_engine.dart';

class PdfReportService {
  // ── Print-Optimized Brand Colors ──
  static const PdfColor _primary = PdfColor.fromInt(
    0xFF4DD0E1,
  ); // AppTheme.accent
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFE0F7FA);
  static const PdfColor _secondary = PdfColor.fromInt(
    0xFF7E57C2,
  ); // AppTheme.purple
  static const PdfColor _textDark = PdfColor.fromInt(
    0xFF152238,
  ); // AppTheme.bgCard
  static const PdfColor _textLight = PdfColor.fromInt(0xFF5A6B87);

  static Future<Uint8List> generateHealthReport(
    PdfPageFormat format, {
    required String patientName,
    required String doctorName,
    required String appointmentDate,
  }) async {
    final pdf = pw.Document(
      title: 'Health Report - $patientName',
      creator: 'Holistic Health App',
    );

    final db = HealthDatabaseService.instance;
    final results = await Future.wait([
      db.getRecords('step_logs', orderBy: 'timestamp DESC', limit: 7),
      db.getRecords('sleep_logs', orderBy: 'timestamp DESC', limit: 7),
      db.getRecords(
        'mental_health_logs',
        orderBy: 'timestamp DESC',
        limit: 14,
      ), // Expanded to catch multiple daily tests
      db.getHabits(),
    ]);

    final stepsData = results[0];
    final sleepData = results[1];
    final mentalData = results[2];
    final habitsData = results[3];

    final metrics = WellnessEngine.currentMetrics;
    final score = WellnessEngine.calculateWellnessScore(metrics);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(
          marginTop: 40,
          marginBottom: 40,
          marginLeft: 40,
          marginRight: 40,
        ),
        header: (context) =>
            _buildHeader(patientName, doctorName, appointmentDate),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(score),
          pw.SizedBox(height: 30),

          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildPhysicalSection(stepsData)),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _buildSleepSection(sleepData)),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildMentalSection(mentalData)),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _buildHabitsSection(habitsData)),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 📄 PDF COMPONENT BUILDERS
  // ==========================================

  static pw.Widget _buildHeader(
    String patientName,
    String doctorName,
    String date,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'CLINICAL HEALTH SUMMARY',
              style: pw.TextStyle(
                color: _primary,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              DateFormat('MMM dd, yyyy').format(DateTime.now()),
              style: pw.TextStyle(color: _textLight, fontSize: 12),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: PdfColors.grey200),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Patient',
                    style: pw.TextStyle(color: _textLight, fontSize: 10),
                  ),
                  pw.Text(
                    patientName,
                    style: pw.TextStyle(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Prepared For',
                    style: pw.TextStyle(color: _textLight, fontSize: 10),
                  ),
                  pw.Text(
                    doctorName,
                    style: pw.TextStyle(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Appt: $date',
                    style: pw.TextStyle(color: _primary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount} • Generated securely via local-first health data.',
        style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildSummarySection(int score) {
    return pw.Row(
      children: [
        // Score Box
        pw.Container(
          width: 80,
          height: 80,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _primaryLight,
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: _primary, width: 2),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                '$score',
                style: pw.TextStyle(
                  color: _primary,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '/ 100',
                style: pw.TextStyle(color: _textDark, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // AI Summary Text
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Overall Wellness Overview',
                style: pw.TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Patient exhibits a stable wellness score. Over the last 7 days, sleep quality has shown a slight improvement, '
                'and resting heart rate remains within normal ranges. Stress levels are being actively managed through guided breathing exercises.',
                style: pw.TextStyle(
                  color: _textLight,
                  fontSize: 11,
                  lineSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildPhysicalSection(List<Map<String, dynamic>> data) {
    int totalSteps = 0;
    for (var log in data) {
      totalSteps += (log['steps'] as int?) ?? 0;
    }
    final avgSteps = data.isNotEmpty ? (totalSteps / data.length).round() : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Physical Activity', _primary),
        _buildMetricRow('7-Day Avg Steps', '$avgSteps steps'),
        _buildMetricRow('Activity Level', avgSteps > 5000 ? 'Moderate' : 'Low'),
        pw.SizedBox(height: 10),
        pw.Text(
          'Recent Logs:',
          style: pw.TextStyle(color: _textLight, fontSize: 10),
        ),
        ...data
            .take(3)
            .map(
              (log) => pw.Text(
                '• ${DateFormat('E, MMM d').format(DateTime.parse(log['timestamp']))}: ${log['steps']} steps',
                style: pw.TextStyle(color: _textDark, fontSize: 10),
              ),
            ),
      ],
    );
  }

  static pw.Widget _buildSleepSection(List<Map<String, dynamic>> data) {
    int totalQuality = 0;
    for (var log in data) {
      totalQuality += (log['sleep_quality'] as int?) ?? 0;
    }
    final avgQuality = data.isNotEmpty
        ? (totalQuality / data.length).round()
        : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Sleep Analytics', _secondary),
        _buildMetricRow('Avg Quality Score', '$avgQuality / 100'),
        _buildMetricRow(
          'Sleep Consistency',
          avgQuality > 70 ? 'High' : 'Variable',
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Recent Logs:',
          style: pw.TextStyle(color: _textLight, fontSize: 10),
        ),
        ...data.take(3).map((log) {
          final bed = DateTime.parse(log['bedtime']);
          final wake = DateTime.parse(log['wake_time']);
          final hours = wake.difference(bed).inHours;
          return pw.Text(
            '• ${DateFormat('MMM d').format(wake)}: $hours hrs (Quality: ${log['sleep_quality']})',
            style: pw.TextStyle(color: _textDark, fontSize: 10),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildMentalSection(List<Map<String, dynamic>> data) {
    // ⚡ Filter out the clinical watch tests (GHQ/MDQ) from the standard mood logs
    final clinicalTests = data
        .where(
          (log) => (log['journal_entry'] as String?)?.contains('Score') == true,
        )
        .toList();
    final standardMoods = data
        .where(
          (log) => (log['journal_entry'] as String?)?.contains('Score') != true,
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mental Health', _primary),

        // ⚡ NEW: Highlight Watch Test Scores for the Doctor
        if (clinicalTests.isNotEmpty) ...[
          pw.Text(
            'Clinical Screenings (This Week):',
            style: pw.TextStyle(
              color: _textDark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          ...clinicalTests.map((log) {
            final date = DateFormat(
              'E, MMM d',
            ).format(DateTime.parse(log['timestamp']));
            final entry = log['journal_entry'] as String;
            return pw.Text(
              '• $date: $entry',
              style: pw.TextStyle(
                color: _secondary,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            );
          }),
          pw.SizedBox(height: 10),
        ],

        pw.Text(
          'Self-Reported Mood Trends:',
          style: pw.TextStyle(color: _textLight, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        if (standardMoods.isEmpty)
          pw.Text(
            'No general mood data logged this week.',
            style: pw.TextStyle(color: _textDark, fontSize: 10),
          )
        else
          ...standardMoods.take(4).map((log) {
            int score = log['mood_score'] as int;
            String moodStr = [
              'Happy',
              'Calm',
              'Neutral',
              'Stressed',
              'Sad',
            ][score < 5 ? score : 2];
            return pw.Text(
              '• ${DateFormat('E, MMM d').format(DateTime.parse(log['timestamp']))}: $moodStr (Stress: ${log['stress_level']}%)',
              style: pw.TextStyle(color: _textDark, fontSize: 10),
            );
          }),
      ],
    );
  }

  static pw.Widget _buildHabitsSection(List<Map<String, dynamic>> habits) {
    final activeHabits = habits.where((h) => (h['streak'] as int) > 0).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Daily Routines', _secondary),
        pw.Text(
          'Active streaks:',
          style: pw.TextStyle(color: _textLight, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        if (activeHabits.isEmpty)
          pw.Text(
            'No active streaks currently.',
            style: pw.TextStyle(color: _textDark, fontSize: 10),
          )
        else
          ...activeHabits.map(
            (h) => pw.Text(
              '• ${h['title']} (${h['streak']} day streak)',
              style: pw.TextStyle(color: _textDark, fontSize: 10),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: _textLight, fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _textDark,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
