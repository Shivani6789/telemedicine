import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';
import 'prescription_form_screen.dart';

/// Doctor-side video consultation screen (answerer role in WebRTC).
/// Receives SDP offer from patient, creates answer, exchanges ICE candidates.
/// On call end → navigates to PrescriptionFormScreen.
class VideoConsultScreen extends StatefulWidget {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;

  const VideoConsultScreen({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
  });

  @override
  State<VideoConsultScreen> createState() => _VideoConsultScreenState();
}

class _VideoConsultScreenState extends State<VideoConsultScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late IO.Socket _socket;

  bool _callConnected = false;
  bool _micMuted = false;
  bool _camOff = false;
  String _status = 'Starting camera...';

  final List<RTCIceCandidate> _remoteCandidates = [];
  bool _isRemoteDescriptionSet = false;

  // Feature 4: Enhanced Video UX (Timer & Call in Progress)
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
          _status = 'Waiting for patient...';
        });
      }
    } catch (e) {
      debugPrint('Camera/Mic error: $e');
      if (mounted) {
        setState(() => _status = 'Camera unavailable, joining anyway...');
      }
    }

    try {
      _peerConnection = await createPeerConnection(_rtcConfig);

      if (_localStream != null) {
        _localStream!.getTracks().forEach((t) {
          _peerConnection!.addTrack(t, _localStream!);
        });
      }

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
        setState(() => _status = 'WebRTC Error: $e');
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
      if (mounted) setState(() => _status = 'Joining room...');
      _socket.emit('join-room', widget.appointmentId);
    });

    // Patient sends offer → doctor creates answer
    _socket.on('offer', (data) async {
      _isRemoteDescriptionSet = false; // Reset for new offer
      if (mounted) setState(() => _status = 'Answering call...');
      
      try {
        final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
        await _peerConnection?.setRemoteDescription(sdp);
        
        _isRemoteDescriptionSet = true;
        for (var candidate in _remoteCandidates) {
          await _peerConnection?.addCandidate(candidate);
        }
        _remoteCandidates.clear();

        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _socket.emit('answer', {
          'roomId': widget.appointmentId,
          'sdp': answer.toMap(),
        });
      } catch (e) {
        debugPrint('Error handling offer: $e');
      }
    });

    _socket.on('ice-candidate', (data) async {
      if (data['candidate'] != null) {
        final c = data['candidate'];
        final candidate = RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']);
        if (_isRemoteDescriptionSet) {
          await _peerConnection?.addCandidate(candidate);
        } else {
          _remoteCandidates.add(candidate);
        }
      }
    });

    _socket.on('call-ended', (_) => _onPatientLeft());

    if (_socket.connected) {
      if (mounted) setState(() => _status = 'Joining room...');
      _socket.emit('join-room', widget.appointmentId);
    } else {
      _socket.connect();
    }
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

  void _endCall() {
    _socket.emit('leave-call', widget.appointmentId);
    _cleanupAndNavigate();
  }

  void _onPatientLeft() => _cleanupAndNavigate();

  void _cleanupAndNavigate() {
    _timer?.cancel();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _socket.dispose();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PrescriptionFormScreen(
            patientId: widget.patientId,
            patientName: widget.patientName,
            appointmentId: widget.appointmentId,
          ),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return _buildCallScreen();
  }

  Widget _buildCallScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Remote (Patient) Video ──
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
                            child: const Icon(Icons.person, size: 56, color: Colors.teal),
                          ),
                          const SizedBox(height: 16),
                          Text(widget.patientName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Age ${widget.patientAge} · ${widget.patientGender}',
                              style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const SizedBox(width: 10, height: 10,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
                            const SizedBox(width: 10),
                            Text(_status, style: TextStyle(color: Colors.grey.shade400)),
                          ]),
                        ],
                      ),
                    ),
            ),

            // ── Local PiP ──
            Positioned(
              right: 12, top: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 108, height: 152,
                  child: _camOff
                      ? Container(color: Colors.grey.shade800,
                          child: const Icon(Icons.videocam_off, color: Colors.white60))
                      : RTCVideoView(_localRenderer, mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ),
            ),

            // ── Patient info tag & Call Progress ──
            Positioned(
              left: 16, top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  if (_callConnected) ...[
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
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
            ),
            
            // Patient Name Tag (bottom left)
            Positioned(
              left: 16, bottom: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  const Icon(Icons.person, color: Colors.teal, size: 16),
                  const SizedBox(width: 8),
                  Text(widget.patientName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
            ),

            // ── Controls ──
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
