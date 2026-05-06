import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../providers/data_provider.dart';
import 'mock_map_screen.dart';
import 'pharmacy_map_screen.dart';
import '../services/api_service.dart';

class PharmacySearchScreen extends StatefulWidget {
  final String? initialMedicine;

  const PharmacySearchScreen({super.key, this.initialMedicine});

  @override
  State<PharmacySearchScreen> createState() => _PharmacySearchScreenState();
}

class _PharmacySearchScreenState extends State<PharmacySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.initialMedicine != null && widget.initialMedicine!.isNotEmpty) {
      _searchController.text = widget.initialMedicine!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialMedicine!);
      });
    }
  }

  void _performSearch(String medicine) {
    if (medicine.trim().isEmpty) return;
    Provider.of<DataProvider>(context, listen: false).searchPharmacies(medicine.trim());
  }

  Future<void> _findNearby() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied')));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        Provider.of<DataProvider>(context, listen: false)
            .fetchNearbyPharmacies(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  // Generate a mock distance since GPS is out of scope
  String _mockDistance() {
    double dist = 0.5 + _random.nextDouble() * 5.0;
    return '${dist.toStringAsFixed(1)} km';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Medicines'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Enter Medicine Name',
                      hintText: 'e.g. Paracetamol',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _performSearch(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Find Nearby Pharmacies (GPS)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _findNearby,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: data.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : data.pharmacies.isEmpty
                      ? const Center(child: Text('No pharmacies found.'))
                      : ListView.builder(
                          itemCount: data.pharmacies.length,
                          itemBuilder: (context, index) {
                            final pharmacy = data.pharmacies[index];
                            final List<dynamic> meds = pharmacy['medicines'] ?? [];
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          pharmacy['name'] ?? 'Unknown Pharmacy',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                            const SizedBox(width: 2),
                                            Text(
                                              pharmacy['distance'] != null ? '${pharmacy['distance']} km' : _mockDistance(),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 14),
                                              SizedBox(width: 4),
                                              Text('Available In Stock', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Area: ${pharmacy['location'] ?? 'N/A'}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Available Medicines:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6.0,
                                      runSpacing: 6.0,
                                      children: meds.map((m) => Chip(
                                        label: Text(m.toString(), style: const TextStyle(fontSize: 12)),
                                        backgroundColor: Colors.blue.shade50,
                                      )).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.directions, color: Colors.teal),
                                        label: const Text('Navigate', style: TextStyle(color: Colors.teal)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MockMapScreen(destinationName: pharmacy['name'] ?? 'Pharmacy'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: data.pharmacies.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                Position position = await Geolocator.getCurrentPosition();
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PharmacyMapScreen(
                        pharmacies: data.pharmacies,
                        initialLat: position.latitude,
                        initialLng: position.longitude,
                      ),
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF00897B),
              label: const Text('View on Map'),
              icon: const Icon(Icons.map_outlined),
            )
          : null,
    );
  }
}
