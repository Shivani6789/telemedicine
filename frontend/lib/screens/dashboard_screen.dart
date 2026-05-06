import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/locale_provider.dart';
import 'appointment_screen.dart';
import 'symptom_checker_screen.dart';
import 'medical_records_screen.dart';
import 'pharmacy_search_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Gradient AppBar ──
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF00695C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(locale.translate('app_title'),
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('${locale.translate('welcome')}, ${auth.name?.split(' ').first ?? 'Patient'}! 👋',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ]),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                            onPressed: () => auth.logout(),
                            tooltip: 'Logout',
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Icon(Icons.badge_outlined, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text('Patient ID: ${auth.patientId ?? '—'}',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [],
          ),

          // ── Offline Mode Banner ──
          if (Provider.of<DataProvider>(context).isOffline)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.red.shade600,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(locale.translate('offline_banner'), 
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(locale.translate('quick_access'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A2332))),
                const SizedBox(height: 16),

                // ── Video Consult Banner (prominent) ──
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AppointmentScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF311B92)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.video_call_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(locale.translate('video_consult'),
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(locale.translate('video_consult_sub'),
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 2-column Grid ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    _DashCard(
                      title: locale.translate('book_apt'),
                      subtitle: locale.translate('book_apt_sub'),
                      icon: Icons.calendar_month_rounded,
                      gradient: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AppointmentScreen())),
                    ),
                    _DashCard(
                      title: locale.translate('symptom_checker'),
                      subtitle: locale.translate('symptom_checker_sub'),
                      icon: Icons.health_and_safety_rounded,
                      gradient: const [Color(0xFF26C6DA), Color(0xFF00ACC1)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SymptomCheckerScreen())),
                    ),
                    _DashCard(
                      title: locale.translate('med_records'),
                      subtitle: locale.translate('med_records_sub'),
                      icon: Icons.folder_open_rounded,
                      gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MedicalRecordsScreen())),
                    ),
                    _DashCard(
                      title: locale.translate('find_meds'),
                      subtitle: locale.translate('find_meds_sub'),
                      icon: Icons.local_pharmacy_rounded,
                      gradient: const [Color(0xFFFF7043), Color(0xFFE64A19)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PharmacySearchScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Tips Card ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF00897B)),
                        const SizedBox(width: 8),
                        Text(locale.translate('health_tips'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ]),
                      const SizedBox(height: 12),
                      _tip(Icons.water_drop, locale.translate('tip_1')),
                      _tip(Icons.directions_walk, locale.translate('tip_2')),
                      _tip(Icons.bed, locale.translate('tip_3')),
                      _tip(Icons.emergency, locale.translate('tip_4')),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF455A64)))),
      ]),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DashCard({
    required this.title, required this.subtitle, required this.icon,
    required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient[1].withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
