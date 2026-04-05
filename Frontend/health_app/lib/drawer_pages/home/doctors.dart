import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pdf_preview_page.dart';
import '../../core/theme/app_theme.dart'; // ⚡ NEW: Centralized theme

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  // ── Sample doctors ──
  static final _doctors = [
    {
      'name': 'Dr. Sarah Wilson',
      'specialty': 'Cardiologist',
      'rating': '4.8',
      'available': true,
      'color': Colors.redAccent,
      'icon': Icons.favorite_rounded,
    },
    {
      'name': 'Dr. Michael Chen',
      'specialty': 'General Physician',
      'rating': '4.9',
      'available': true,
      'color': AppTheme.accent, // ⚡ Themed
      'icon': Icons.local_hospital_rounded,
    },
    {
      'name': 'Dr. Sarah Kline',
      'specialty': 'Psychiatrist',
      'rating': '4.9',
      'available': true,
      'color': AppTheme.purple, // ⚡ Themed
      'icon': Icons.psychology_rounded,
    },
    {
      'name': 'Dr. Emily Roberts',
      'specialty': 'Nutritionist',
      'rating': '4.7',
      'available': false,
      'color': AppTheme.green, // ⚡ Themed
      'icon': Icons.restaurant_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mainBackgroundGradient, // ⚡ Centralized Theme
      ),
      child: SafeArea(
        // ⚡ OPTIMIZATION: Converted to ListView for directory scaling
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'Doctors',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find and book appointments',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            // ── Doctor Cards ──
            ..._doctors.map((doc) => _buildDoctorCard(doc)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    final color = doc['color'] as Color;
    final available = doc['available'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(doc['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doc['specialty'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppTheme.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        doc['rating'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: available
                          ? AppTheme.green.withOpacity(0.12)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: available ? AppTheme.green : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Viewing profile of ${doc['name']}'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.bgCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: available ? () => _showBookingSheet(doc) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.bgDark,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Booking Bottom Sheet ─────────────────────────────────────────────────

  void _showBookingSheet(Map<String, dynamic> doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingSheet(doctorName: doc['name'] as String),
    );
  }
}

// ─── Booking Sheet Widget ───────────────────────────────────────────────────

class _BookingSheet extends StatefulWidget {
  final String doctorName;
  const _BookingSheet({required this.doctorName});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedSlot = -1;

  final _timeSlots = [
    '9:00 AM',
    '10:30 AM',
    '11:30 AM',
    '2:00 PM',
    '3:30 PM',
    '5:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Book with ${widget.doctorName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Date selector
          const Text(
            'Select Date',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final date = DateTime.now().add(Duration(days: i + 1));
                final isSelected = _selectedDate.day == date.day;
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 55,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent : Colors.white10,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[(date.weekday - 1) % 7],
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.bgDark
                                : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? AppTheme.bgDark : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Time slots
          const Text(
            'Select Time',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_timeSlots.length, (i) {
              final isSelected = _selectedSlot == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accent : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.accent : Colors.white10,
                    ),
                  ),
                  child: Text(
                    _timeSlots[i],
                    style: TextStyle(
                      color: isSelected ? AppTheme.bgDark : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Generate PDF and Show Preview
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlot >= 0
                  ? () async {
                      const storage = FlutterSecureStorage();
                      final pName =
                          await storage.read(key: 'username') ?? 'Patient';

                      if (!mounted) return;
                      Navigator.pop(context); // Close the bottom sheet

                      final dateStr =
                          '${_selectedDate.day}/${_selectedDate.month} at ${_timeSlots[_selectedSlot]}';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfPreviewPage(
                            doctorName: widget.doctorName,
                            patientName: pName,
                            appointmentDetails: dateStr,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.bgDark,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Generate Report & Book',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
