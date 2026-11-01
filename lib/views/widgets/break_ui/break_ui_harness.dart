import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

enum BreakUiMode {
  live,
  worstCase,
  empty,
  single,
}

/// Adversarial data factory based on Emil Kowalski's break-ui catalog.
/// Generates realistic worst-case values to stress-test layout bounds,
/// unbreakable strings, diacritics, CJK, and numeric formatting.
abstract class BreakUiDataFactory {
  static List<Data> getWorstCaseAppointments() {
    return [
      // 1. Long compound name with diacritics + unbreakable email
      Data(
        appointmentId: '9f8e7d6c-5b4a-4c3d-8e2f-1a0b9c8d7e6f',
        appointmentDatetime: '2026-11-01T09:30:00.000Z',
        appointmentStatus: 1, // Scheduled
        appointmentNote:
            'Patient requested consultation for twin pregnancy with previous gestational diabetes. Requires comprehensive ultrasound Doppler scan.',
        serviceBranchId: 'sb-worst-01',
        user: User(
          userId: 'u-worst-01',
          userName: 'aleksandra_w',
          userFullName: 'Aleksandra Wiśniewska-Kowalczyk',
          userEmail: 'bartholomew.fitzgerald@northwind-industries-holdings.example.com',
          userNric: '940512-10-5432',
          userPhone: '+60 11-1234 5678 ext. 9012',
        ),
        service: Service(
          serviceId: 'srv-01',
          serviceName: 'Comprehensive 5D Fetal Ultrasound & Advanced Genetic Consultation',
          serviceTime: '60',
          servicePrice: '450.00',
          serviceBookingFee: '50.00',
          doctorType: 1,
        ),
        branch: Branch(
          branchId: 'b-01',
          branchName: 'Klinik Aurora Subang Jaya Eco Sanctuary Flagship Centre',
        ),
        doctor: Doctor(doctorName: 'Dr. Christopher Alexander Montgomery III'),
      ),

      // 2. Ultra-short 2-letter name + shortest realistic email + zero booking fee
      Data(
        appointmentId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        appointmentDatetime: '2026-11-01T11:00:00.000Z',
        appointmentStatus: 5, // Completed
        appointmentNote: '',
        serviceBranchId: 'sb-worst-02',
        user: User(
          userId: 'u-worst-02',
          userName: 'jo',
          userFullName: 'Jo',
          userEmail: 'a@b.co',
          userNric: '010203-08-1122',
          userPhone: '0123456789',
        ),
        service: Service(
          serviceId: 'srv-02',
          serviceName: 'General Consultation',
          serviceTime: '15',
          servicePrice: '60.00',
          serviceBookingFee: '0.00',
          doctorType: 1,
        ),
        branch: Branch(
          branchId: 'b-02',
          branchName: 'Aurora Bangi',
        ),
        doctor: Doctor(doctorName: 'Dr. Siti'),
      ),

      // 3. CJK non-spaced name + huge 7-digit currency amount
      Data(
        appointmentId: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
        appointmentDatetime: '2026-11-01T14:15:00.000Z',
        appointmentStatus: 3, // In-progress / Arrived
        appointmentNote: 'VIP client package renewal with multi-session booking voucher.',
        serviceBranchId: 'sb-worst-03',
        user: User(
          userId: 'u-worst-03',
          userName: 'xiuying_wang',
          userFullName: '王秀英',
          userEmail: 'xiuying.wang+aurora-specialist-portal@hospital.example.org',
          userNric: '880808-14-8888',
          userPhone: '+60 17-888 8888',
        ),
        service: Service(
          serviceId: 'srv-03',
          serviceName: 'Aesthetic Laser & Regenerative Skin Therapy Protocol Level 3',
          serviceTime: '90',
          servicePrice: '1234567.89',
          serviceBookingFee: '50000.00',
          doctorType: 2,
        ),
        branch: Branch(
          branchId: 'b-03',
          branchName: 'Aurora Pavilion Bukit Jalil Premier Suite',
        ),
        doctor: Doctor(doctorName: 'Dr. Tan Mei Ling'),
      ),

      // 4. RTL Name + Missing optional fields (null NRIC, null phone, null note)
      Data(
        appointmentId: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a',
        appointmentDatetime: '2026-11-01T16:00:00.000Z',
        appointmentStatus: 2, // Cancelled
        appointmentNote: null,
        serviceBranchId: 'sb-worst-04',
        user: User(
          userId: 'u-worst-04',
          userName: 'nur_al_huda',
          userFullName: 'نور الهدى عبد الرحمن',
          userEmail: 'nur.alhuda@embassy.example.com',
          userNric: null,
          userPhone: null,
        ),
        service: Service(
          serviceId: 'srv-04',
          serviceName: 'Vaccination & Infant Wellness Assessment',
          serviceTime: '30',
          servicePrice: '120.00',
          serviceBookingFee: null,
          doctorType: 1,
        ),
        branch: Branch(
          branchId: 'b-04',
          branchName: 'Aurora Cyberjaya Smart Clinic',
        ),
        doctor: Doctor(doctorName: 'Dr. Ahmad Fauzi'),
      ),
    ];
  }

  static List<Data> getSingleAppointment() {
    return [getWorstCaseAppointments().first];
  }

  static List<Data> getEmptyAppointments() {
    return <Data>[];
  }
}

/// Floating dev harness widget to switch between Live Data and Adversarial Worst-Case Data.
class BreakUiDevHarness extends StatelessWidget {
  final BreakUiMode currentMode;
  final ValueChanged<BreakUiMode> onModeChanged;

  const BreakUiDevHarness({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Only render in debug mode or if explicitly activated
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          elevation: 16,
          shadowColor: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // slate-800
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bug_report_rounded, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Break UI',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _segment('Live Data', BreakUiMode.live),
                _segment('Worst-Case', BreakUiMode.worstCase),
                _segment('Empty', BreakUiMode.empty),
                _segment('Single', BreakUiMode.single),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segment(String label, BreakUiMode mode) {
    final isActive = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: EmilMotion.releaseDuration,
        curve: EmilMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
