import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'pharmacy_search_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _allRecords = [];
  List<dynamic> _filtered = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedDate; // YYYY-MM-DD

  final _tabs = const ['All', 'Online', 'Offline', 'Prescriptions'];
  final _categories = ['', 'Online Consultation', 'Offline Visit', 'Prescription'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChange);
    _searchCtrl.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) _applyFilters();
  }

  void _onSearch() {
    setState(() => _searchQuery = _searchCtrl.text);
    _applyFilters();
  }

  Future<void> _loadRecords({String? category}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getRecords(auth.userId!);
      setState(() {
        _allRecords = List.from(data);
        if (_allRecords.isNotEmpty) {
          _allRecords[0] = {..._allRecords[0], 'isLatest': true};
        }
        _applyFilters();
      });
    } catch (_) {
      // Offline — show cached via shared_preferences handled by DataProvider
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final catIndex = _tabController.index;
    final catFilter = _categories[catIndex];

    List<dynamic> result = List.from(_allRecords);

    // Tab category filter
    if (catFilter.isNotEmpty) {
      result = result.where((r) => (r['category'] ?? '').toString() == catFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((r) =>
        (r['doctorName'] ?? '').toString().toLowerCase().contains(q) ||
        (r['diagnosis'] ?? '').toString().toLowerCase().contains(q) ||
        (r['condition'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }

    // Date filter
    if (_selectedDate != null) {
      result = result.where((r) {
        final dt = r['dateTime'];
        return dt != null && dt.toString().startsWith(_selectedDate!);
      }).toList();
    }

    setState(() => _filtered = result);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
      _applyFilters();
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Medical Records', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search + Date Filter Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by doctor or diagnosis...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _selectedDate != null ? _clearDate : _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedDate != null ? const Color(0xFF00897B) : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(children: [
                    Icon(
                      _selectedDate != null ? Icons.close : Icons.calendar_today,
                      size: 16,
                      color: _selectedDate != null ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedDate ?? 'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedDate != null ? Colors.white : Colors.grey,
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Records List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic r) {
    final category = r['category'] ?? 'Online Consultation';
    final dateTime = r['dateTime'] ?? '';
    String formattedDate = '';
    if (dateTime.isNotEmpty) {
      try { formattedDate = DateFormat('MMM d, yyyy · h:mm a').format(DateTime.parse(dateTime).toLocal()); }
      catch (_) { formattedDate = dateTime; }
    }

    final Color catColor;
    final IconData catIcon;
    switch (category) {
      case 'Prescription':
        catColor = Colors.purple; catIcon = Icons.medication_rounded; break;
      case 'Offline Visit':
        catColor = Colors.orange; catIcon = Icons.local_hospital; break;
      default:
        catColor = Colors.blue; catIcon = Icons.video_call;
    }

    // Extract medicine names for pharmacy search
    List<String> medicineNames = [];
    if (r['medicines'] != null && r['medicines'] is List) {
      medicineNames = (r['medicines'] as List).map((m) => m['name'].toString()).toList();
    } else if (r['prescription'] != null) {
      medicineNames = [r['prescription'].toString()];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: catColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(catIcon, color: catColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(r['doctorName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    if (r['isLatest'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(category, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            if (formattedDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(formattedDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ]),
            ],
            if (r['diagnosis'] != null) ...[
              const Divider(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.medical_information, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text('Diagnosis: ${r['diagnosis']}', style: const TextStyle(fontSize: 13))),
              ]),
            ],
            if (r['medicines'] != null && r['medicines'] is List) ...[
              const SizedBox(height: 6),
              ...(r['medicines'] as List).map((m) {
                final timings = <String>[];
                if (m['morning'] == true) timings.add('Morn');
                if (m['afternoon'] == true) timings.add('Aft');
                if (m['evening'] == true) timings.add('Eve');
                final timingStr = timings.isNotEmpty ? '(${timings.join('-')})' : '';
                
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF00897B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m['name']} — ${m['dosage']} $timingStr',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2332)),
                        ),
                      ),
                      Text(
                        m['duration'],
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      Text('Digitally Signed', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                      SizedBox(height: 4),
                      Icon(Icons.verified_user, color: Colors.blue, size: 20),
                    ],
                  ),
                ],
              ),
            ],
            if (r['prescription'] != null && r['medicines'] == null) ...[
              const Divider(height: 20),
              Text('Prescription: ${r['prescription']}',
                  style: const TextStyle(fontSize: 13)),
            ],
            if (r['bookedSlot'] != null) ...[
              const Divider(height: 20),
              Text('Slot: ${r['date'] ?? ''} ${r['bookedSlot']}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Notes: ${r['notes']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            ],
            if (medicineNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.local_pharmacy, size: 16),
                label: const Text('Find Medicines at Nearby Pharmacy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PharmacySearchScreen(
                        initialMedicine: medicineNames.join(', ')),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No records found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          if (_searchQuery.isNotEmpty || _selectedDate != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () { _searchCtrl.clear(); _clearDate(); },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}
