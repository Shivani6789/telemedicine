import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'video_consult_screen.dart';

/// Doctor Dashboard: shows pending/completed online consultation queue.
/// Doctor can toggle their availability and join video calls.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _appointments = [];
  bool _isLoading = false;
  String? _error;
  bool _isAvailable = false;
  bool _togglingAvailability = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = auth.linkedDoctorId;

    if (doctorId == null || doctorId.isEmpty) {
      setState(() => _error =
          'Doctor profile not linked.\nLinkedDoctorId is null.\n\nMake sure you ran node seed.js and logged in fresh.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all appointments (pending online)
      final data = await ApiService.getDoctorAppointments(doctorId);

      // Also fetch doctor's current availability from the doctors list
      final doctors = await ApiService.getDoctors();
      final myDoc = (doctors as List).firstWhere(
        (d) => d['_id'].toString() == doctorId,
        orElse: () => null,
      );

      setState(() {
        _appointments = data;
        if (myDoc != null) {
          _isAvailable = myDoc['availableNow'] == true;
        }
      });
    } catch (e) {
      setState(() =>
          _error = 'Failed to load appointments.\nError: $e\n\nAre you online?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = auth.linkedDoctorId;
    if (doctorId == null) return;

    setState(() => _togglingAvailability = true);
    try {
      final res = await ApiService.toggleDoctorAvailability(doctorId);
      setState(() => _isAvailable = res['availableNow'] == true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Availability updated'),
          backgroundColor:
              _isAvailable ? const Color(0xFF00897B) : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to toggle availability: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _togglingAvailability = false);
    }
  }

  List<dynamic> get _pendingAppts =>
      _appointments.where((a) => a['status'] == 'pending').toList();
  List<dynamic> get _completedAppts =>
      _appointments.where((a) => a['status'] == 'completed').toList();

  // ─────────────────────────────── UI ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadAppointments,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => auth.logout(),
                tooltip: 'Logout',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF004D40),
                      Color(0xFF00695C),
                      Color(0xFF00897B)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor identity row
                        Row(children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.person_pin_rounded,
                                color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.name ?? 'Doctor',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Doctor Dashboard',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Availability toggle row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isAvailable
                                    ? Colors.greenAccent
                                    : Colors.orange.shade300,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isAvailable
                                            ? Colors.greenAccent
                                            : Colors.orange)
                                        .withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isAvailable
                                        ? 'Online — accepting patients'
                                        : 'Offline — unavailable',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    _isAvailable
                                        ? 'Patients can book online consults'
                                        : 'Toggle ON to accept online consults',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            _togglingAvailability
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70))
                                : Switch(
                                    value: _isAvailable,
                                    onChanged: (_) => _toggleAvailability(),
                                    activeColor: Colors.greenAccent,
                                    inactiveThumbColor: Colors.orange.shade300,
                                    inactiveTrackColor:
                                        Colors.orange.withOpacity(0.3),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFF80CBC4),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(_isLoading
                          ? 'Queue'
                          : 'Queue (${_pendingAppts.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(_isLoading
                          ? 'Completed'
                          : 'Completed (${_completedAppts.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00897B)))
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(_pendingAppts, isPending: true),
                      _buildList(_completedAppts, isPending: false),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isPending}) {
    if (items.isEmpty) return _buildEmpty(isPending);
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: const Color(0xFF00897B),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, i) =>
            _buildAppointmentCard(items[i], isPending: isPending),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appt,
      {required bool isPending}) {
    final createdAt = appt['createdAt'] ?? '';
    String timeStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        timeStr = DateFormat('h:mm a · MMM d, yyyy').format(dt);
      } catch (_) {}
    }

    final patientName = appt['patientName'] ?? 'Unknown Patient';
    final patientAge = appt['patientAge']?.toString() ?? '—';
    final patientGender = appt['patientGender'] ?? 'N/A';
    final patientUserId = appt['patientId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Top coloured strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPending
                    ? [const Color(0xFF00897B), const Color(0xFF26C6DA)]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient row
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isPending
                            ? [const Color(0xFF26C6DA), const Color(0xFF00897B)]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A2332))),
                        const SizedBox(height: 2),
                        Text('Age $patientAge · $patientGender',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  _statusChip(isPending),
                ]),

                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 5),
                    Text('Requested $timeStr',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11)),
                  ]),
                ],

                if (isPending) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.video_call_rounded, size: 20),
                      label: const Text('Join Video Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        elevation: 2,
                        shadowColor: const Color(0xFF00897B).withOpacity(0.3),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoConsultScreen(
                              appointmentId: appt['_id']?.toString() ?? '',
                              patientId: patientUserId,
                              patientName: patientName,
                              patientAge: appt['patientAge'] ?? 0,
                              patientGender: patientGender,
                            ),
                          ),
                        ).then((_) => _loadAppointments());
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isPending) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.orange.shade50
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isPending
                ? Colors.orange.shade200
                : Colors.green.shade200),
      ),
      child: Text(
        isPending ? 'Waiting' : 'Done',
        style: TextStyle(
          color: isPending
              ? Colors.orange.shade700
              : Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.inbox_outlined : Icons.task_alt_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isPending
                ? 'No patients waiting'
                : 'No completed consultations',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? (_isAvailable
                    ? 'Pull down to refresh when a patient books'
                    : 'Toggle online above to accept patients')
                : 'Completed calls will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          if (isPending) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loadAppointments,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 56, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
