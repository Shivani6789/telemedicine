import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Prescription form shown to doctor after a video call ends.
/// Submits structured prescription → auto-links to patient's Medical Records.
class PrescriptionFormScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? appointmentId;

  const PrescriptionFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  // Each entry: {'name': ctrl, 'dosage': ctrl, 'duration': ctrl, 'morning': bool, 'afternoon': bool, 'evening': bool}
  final List<Map<String, dynamic>> _medicines = [];

  @override
  void initState() {
    super.initState();
    _addMedicine(); // Start with one medicine row
  }
  void _addMedicine() {
    setState(() {
      _medicines.add({
        'name': TextEditingController(),
        'dosage': TextEditingController(),
        'duration': TextEditingController(),
        'morning': true,
        'afternoon': false,
        'evening': true,
      });
    });
  }

  void _removeMedicine(int index) {
    for (var v in _medicines[index].values) {
      if (v is TextEditingController) v.dispose();
    }
    setState(() {
      _medicines.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one medicine')));
      return;
    }

    setState(() => _isLoading = true);

    final medicines = _medicines.map((m) => {
      'name': m['name']!.text.trim(),
      'dosage': m['dosage']!.text.trim(),
      'duration': m['duration']!.text.trim(),
      'morning': m['morning'],
      'afternoon': m['afternoon'],
      'evening': m['evening'],
    }).toList();

    try {
      await ApiService.submitPrescription(
        patientId: widget.patientId,
        appointmentId: widget.appointmentId,
        diagnosis: _diagnosisCtrl.text.trim(),
        medicines: medicines,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Prescription saved and added to patient records'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop back to doctor dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    for (final m in _medicines) {
      for (var v in m.values) {
        if (v is TextEditingController) v.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Write Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient Info Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('PATIENT', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(widget.patientName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Diagnosis ──
              _sectionLabel('Diagnosis *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _diagnosisCtrl,
                decoration: _inputDecoration('e.g. Hypertension, Viral Fever...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Diagnosis is required' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // ── Medicines ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Medicines *'),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Medicine'),
                    onPressed: _addMedicine,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._medicines.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF00897B).withOpacity(0.15),
                            child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('Medicine ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (_medicines.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _removeMedicine(i),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: m['name'],
                            decoration: _inputDecoration('Medicine name'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: m['dosage'],
                            decoration: _inputDecoration('Dosage (e.g. 500mg)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Timings:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          _timingChip('Morn', i, 'morning'),
                          _timingChip('Aft', i, 'afternoon'),
                          _timingChip('Eve', i, 'evening'),
                          const Spacer(),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: m['duration'],
                              decoration: _inputDecoration('Duration (e.g. 5 days)'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ── Notes ──
              _sectionLabel('Doctor\'s Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                decoration: _inputDecoration('Additional advice, diet, follow-up...'),
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'Saving...' : 'Save Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timingChip(String label, int medicineIndex, String key) {
    bool isSelected = _medicines[medicineIndex][key];
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (val) => setState(() => _medicines[medicineIndex][key] = val),
        selectedColor: const Color(0xFF00897B),
        checkmarkColor: Colors.white,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2332)));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00897B))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
