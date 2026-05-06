import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class PharmacyMapScreen extends StatefulWidget {
  final List<dynamic> pharmacies;
  final double initialLat;
  final double initialLng;

  const PharmacyMapScreen({
    super.key,
    required this.pharmacies,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    for (var p in widget.pharmacies) {
      if (p['latitude'] != null && p['longitude'] != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(p['_id'] ?? p['name']),
            position: LatLng(p['latitude'], p['longitude']),
            infoWindow: InfoWindow(
              title: p['name'],
              snippet: 'Area: ${p['location']}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }
    
    // User marker
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(widget.initialLat, widget.initialLng),
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Map'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.initialLat, widget.initialLng),
          zoom: 14,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: const Text('List View'),
        icon: const Icon(Icons.list),
        backgroundColor: const Color(0xFF00897B),
      ),
    );
  }
}
