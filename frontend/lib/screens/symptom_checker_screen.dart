import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'appointment_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final List<String> _availableSymptoms = [
    'chest pain', 'palpitations', 'breathlessness', 'dizziness',
    'cough', 'fever', 'headache', 'fatigue', 'sore throat', 'runny nose',
    'wheezing', 'shortness of breath',
    'skin rash', 'itching', 'hives',
    'child fever', 'crying constantly', 'loss of appetite',
    'joint pain', 'back pain', 'swollen joints',
    'nausea', 'vomiting', 'abdominal pain',
  ];

  final Set<String> _selected = {};
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Symptom Checker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Icon(Icons.health_and_safety, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Smart Doctor Matching', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Select your symptoms and get matched with the best available doctors.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Symptom Chips ──
            const Text('Select your symptoms:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _availableSymptoms.map((s) {
                final sel = _selected.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: sel,
                  selectedColor: const Color(0xFF00897B).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF00897B),
                  labelStyle: TextStyle(
                    color: sel ? const Color(0xFF00897B) : Colors.grey.shade700,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: sel ? const Color(0xFF00897B) : Colors.grey.shade300),
                  onSelected: (val) => setState(() => val ? _selected.add(s) : _selected.remove(s)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Selected Count ──
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00897B), size: 16),
                  const SizedBox(width: 8),
                  Text('${_selected.length} symptom(s) selected',
                      style: const TextStyle(color: Color(0xFF00897B), fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('Clear'),
                  ),
                ]),
              ),
            const SizedBox(height: 16),

            // ── Analyze Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search_rounded),
                label: Text(_isLoading ? 'Analysing...' : 'Find Matching Doctors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: (_selected.isEmpty || _isLoading) ? null : _analyze,
              ),
            ),
            const SizedBox(height: 24),

            // ── Results ──
            if (_result != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    setState(() { _isLoading = true; _result = null; });
    try {
      final res = await Provider.of<DataProvider>(context, listen: false)
          .analyzeSymptoms(_selected.toList());
      setState(() => _result = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildResults() {
    final condition = _result!['condition'] ?? '';
    final severity = _result!['severity'] ?? 'low';
    final message = _result!['message'] ?? '';
    final recommendations = (_result!['recommendations'] as List?) ?? [];

    final Color sevColor = severity == 'high' ? Colors.red
        : severity == 'medium' ? Colors.orange : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Condition Summary ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sevColor.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: sevColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(severity.toUpperCase(),
                    style: TextStyle(color: sevColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(condition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ]),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Recommended Doctors ──
        if (recommendations.isNotEmpty) ...[
          const Text('Top Recommended Doctors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...recommendations.asMap().entries.map((e) => _buildDoctorCard(e.key, e.value)),
        ],
      ],
    );
  }

  Widget _buildDoctorCard(int rank, dynamic rec) {
    final doc = rec['doctor'];
    final explanation = rec['explanation'] ?? '';
    final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
    final isAvailable = doc['availableNow'] == true;
    final rating = (doc['rating'] as num?)?.toDouble() ?? 4.0;

    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank < 3 ? medals[rank] : '⭐';

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
              Text(medal, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(doc['specialization'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ]),
              ),
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text('Online Now', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              ...List.generate(5, (i) => Icon(
                i < rating.floor() ? Icons.star : (i < rating ? Icons.star_half : Icons.star_border),
                color: Colors.amber, size: 14,
              )),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF00897B)),
                const SizedBox(width: 6),
                Expanded(child: Text(explanation, style: const TextStyle(color: Color(0xFF00897B), fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(isAvailable ? 'Book / Consult Now' : 'Book Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? const Color(0xFF00897B) : Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentScreen(filterSpecialization: doc['specialization']),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
