import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';

/// Patient-side video consultation with real WebRTC (flutter_webrtc).
/// The patient joins first, waits for doctor, then creates the SDP offer.
class OnlineConsultScreen extends StatefulWidget {
  final String appointmentId; // Used as the WebRTC room ID
  final String doctorId;
  final String doctorName;
  final String pName;
  final int pAge;
  final String pGender;

  const OnlineConsultScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.pName,
    required this.pAge,
    required this.pGender,
  });

  @override
  State<OnlineConsultScreen> createState() => _OnlineConsultScreenState();
}

class _OnlineConsultScreenState extends State<OnlineConsultScreen> {
  // WebRTC objects
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Signaling socket
  late IO.Socket _socket;

  // UI state
  bool _callConnected = false;
  bool _callEnded = false;
  bool _micMuted = false;
  bool _camOff = false;
  String _status = 'Initialising camera...';

  // Timer Feature
  Timer? _timer;
  int _secondsElapsed = 0;

  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  // ───────────────────────── WebRTC Setup ──────────────────────────

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user', 'width': 1280, 'height': 720},
      });
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = _localStream;
          _status = 'Waiting for doctor to join...';
        });
      }

      // Create peer connection
      _peerConnection = await createPeerConnection(_rtcConfig);

      // Add local tracks
      _localStream!.getTracks().forEach((t) {
        _peerConnection!.addTrack(t, _localStream!);
      });

      // Remote track → render
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty && mounted) {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
            _callConnected = true;
            _status = 'Connected';
            _startTimer();
          });
        }
      };

      // ICE → signal to other peer
      _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate != null) {
          _socket.emit('ice-candidate', {
            'roomId': widget.appointmentId,
            'candidate': candidate.toMap(),
          });
        }
      };

      _connectSocket();
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Camera/Mic error: $e');
      }
    }
  }

  void _connectSocket() {
    _socket = IO.io(
      ApiService.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket.onConnect((_) {
      if (mounted) setState(() => _status = 'Waiting for doctor...');
      _socket.emit('join-room', widget.appointmentId);
    });

    // Doctor arrived → patient (existing peer) creates offer
    _socket.on('user-joined', (_) async {
      if (mounted) setState(() => _status = 'Doctor joined — connecting...');
      await _createAndSendOffer();
    });

    // Doctor sent answer → set remote description
    _socket.on('answer', (data) async {
      final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
      await _peerConnection?.setRemoteDescription(sdp);
    });

    // ICE candidates from doctor
    _socket.on('ice-candidate', (data) async {
      if (data['candidate'] != null) {
        final c = data['candidate'];
        await _peerConnection?.addCandidate(
          RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
        );
      }
    });

    // Doctor ended the call
    _socket.on('call-ended', (_) => _onCallEnded());

    if (_socket.connected) {
      if (mounted) setState(() => _status = 'Waiting for doctor...');
      _socket.emit('join-room', widget.appointmentId);
    } else {
      _socket.connect();
    }
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    await _peerConnection!.setLocalDescription(offer);
    _socket.emit('offer', {
      'roomId': widget.appointmentId,
      'sdp': offer.toMap(),
    });
  }

  // ───────────────────────── Controls ─────────────────────────────

  void _endCall() {
    _socket.emit('leave-call', widget.appointmentId);
    _onCallEnded();
  }

  void _onCallEnded() {
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _timer?.cancel();
    if (mounted) setState(() => _callEnded = true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMic() {
    final tracks = _localStream?.getAudioTracks();
    if (tracks != null && tracks.isNotEmpty) {
      final enabled = !tracks[0].enabled;
      tracks[0].enabled = enabled;
      setState(() => _micMuted = !enabled);
    }
  }

  void _toggleCamera() {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      final enabled = !tracks[0].enabled;
      tracks[0].enabled = enabled;
      setState(() => _camOff = !enabled);
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _socket.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ───────────────────────── UI ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _callEnded ? _buildEndedScreen() : _buildCallScreen();
  }

  Widget _buildEndedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.15),
              ),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('Consultation Complete', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Dr. ${widget.doctorName} will add your prescription shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text('It will appear in your Medical Records.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Remote Video (full-screen) ──
            Positioned.fill(
              child: _callConnected
                  ? RTCVideoView(_remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                  : Container(
                      color: const Color(0xFF1A2332),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.teal.withOpacity(0.2),
                            child: const Icon(Icons.person, size: 60, color: Colors.teal),
                          ),
                          const SizedBox(height: 16),
                          Text(widget.doctorName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const SizedBox(width: 8, height: 8,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
                            const SizedBox(width: 10),
                            Text(_status, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          ]),
                        ],
                      ),
                    ),
            ),

            // ── Local Video PiP ──
            Positioned(
              right: 12, top: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 108, height: 152,
                  child: _camOff
                      ? Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.videocam_off, color: Colors.white60),
                        )
                      : RTCVideoView(_localRenderer, mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ),
            ),

            // ── Doctor name tag ──
            Positioned(
              left: 16, bottom: 90,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  const Icon(Icons.local_hospital, color: Colors.teal, size: 16),
                  const SizedBox(width: 8),
                  Text(widget.doctorName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
            ),

            // ── Call Progress Overlay ──
            Positioned(
              top: 16, left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.lock, color: Colors.greenAccent, size: 12),
                      SizedBox(width: 4),
                      Text('Encrypted WebRTC', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)),
                    child: Row(children: [
                      if (_callConnected) ...[
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
                        ),
                        const SizedBox(width: 8),
                        Text('Call in Progress - ${_formatTime(_secondsElapsed)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ] else ...[
                        const SizedBox(width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
                        const SizedBox(width: 8),
                        const Text('Connecting...', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ]),
                  ),
                ],
              ),
            ),

            // ── Control Bar ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ctrlBtn(icon: _micMuted ? Icons.mic_off : Icons.mic,
                        color: _micMuted ? Colors.red : Colors.white,
                        bg: Colors.white24, onTap: _toggleMic),
                    _ctrlBtn(icon: Icons.call_end, color: Colors.white,
                        bg: Colors.red, onTap: _endCall, size: 60),
                    _ctrlBtn(icon: _camOff ? Icons.videocam_off : Icons.videocam,
                        color: _camOff ? Colors.red : Colors.white,
                        bg: Colors.white24, onTap: _toggleCamera),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn({required IconData icon, required Color color,
      required Color bg, required VoidCallback onTap, double size = 50}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Icon(icon, color: color, size: size * 0.44),
      ),
    );
  }
}
