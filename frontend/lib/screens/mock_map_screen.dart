import 'package:flutter/material.dart';

class MockMapScreen extends StatelessWidget {
  final String destinationName;

  const MockMapScreen({super.key, required this.destinationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Navigating', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Simulated Map Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE0E0E0),
              child: CustomPaint(
                painter: MapGridPainter(),
              ),
            ),
          ),
          
          // Route Line Mock
          Positioned.fill(
            child: Center(
              child: CustomPaint(
                size: const Size(200, 300),
                painter: RouteLinePainter(),
              ),
            ),
          ),

          // Origin Marker
          const Positioned(
            bottom: 120,
            left: 100,
            child: Column(
              children: [
                Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40),
                Text('You', style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
              ],
            ),
          ),

          // Destination Marker
          Positioned(
            top: 100,
            right: 80,
            child: Column(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 45),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.white.withOpacity(0.8),
                  child: Text(destinationName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Navigation Instructions Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.turn_right, color: Colors.teal, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('In 200m, turn right', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('onto Main Street towards $destinationName', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('1.2 km', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('5 mins', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Exit Navigation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0;

    // Draw some mock roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), paint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.4, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.8, size.height), paint);
    
    // Minor roads
    paint.strokeWidth = 2.0;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.6, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouteLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.7)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.moveTo(-80, 100);
    path.lineTo(-80, -20);
    path.lineTo(60, -20);
    path.lineTo(60, -100);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
