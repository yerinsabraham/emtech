import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/call_service.dart';
import '../models/call_model.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final CallModel call;
  final bool isOutgoing; // true for caller, false for receiver
  final String currentUserId;
  final String currentUserName;

  const CallScreen({
    super.key,
    required this.call,
    required this.isOutgoing,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    final callService = context.read<CallService>();
    
    try {
      // Initialize Agora if not already initialized
      await callService.initializeAgora();

      // Generate a unique UID for this user (using hashCode of userId)
      final uid = widget.currentUserId.hashCode.abs() % 1000000;

      // Join the call channel
      await callService.joinCall(widget.call.channelName, uid);

      // If this is the receiver (admin), mark call as answered
      if (!widget.isOutgoing) {
        await callService.answerCall(widget.call.callId);
      }

      setState(() {
        _isCallConnected = true;
      });

      // Start call timer
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    final callService = context.read<CallService>();
    await callService.endCall();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080C14),
        body: SafeArea(
          child: Consumer<CallService>(
            builder: (context, callService, child) {
              return Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _endCall,
                        ),
                        const Spacer(),
                        Text(
                          _isCallConnected ? 'Connected' : 'Connecting...',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Caller/Receiver info
                  Column(
                    children: [
                      // Avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: widget.call.callerPhotoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  widget.call.callerPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(),
                                ),
                              )
                            : _buildDefaultAvatar(),
                      ),
                      const SizedBox(height: 24),

                      // Name
                      Text(
                        widget.isOutgoing ? 'Support Team' : widget.call.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Call status/duration
                      Text(
                        _isCallConnected
                            ? _formatDuration(_secondsElapsed)
                            : widget.isOutgoing
                                ? 'Calling...'
                                : 'Incoming call',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Call controls
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute button
                        _buildControlButton(
                          icon: callService.isMuted ? Icons.mic_off : Icons.mic,
                          label: callService.isMuted ? 'Unmute' : 'Mute',
                          color: callService.isMuted
                              ? Colors.red
                              : const Color(0xFF374151),
                          onPressed: () => callService.toggleMute(),
                        ),

                        // End call button
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'End',
                          color: Colors.red,
                          size: 72,
                          iconSize: 32,
                          onPressed: _endCall,
                        ),

                        // Speaker button
                        _buildControlButton(
                          icon: callService.isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          label: 'Speaker',
                          color: callService.isSpeakerOn
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF374151),
                          onPressed: () => callService.toggleSpeaker(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        widget.isOutgoing
            ? 'S'
            : widget.call.callerName.isNotEmpty
                ? widget.call.callerName[0].toUpperCase()
                : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    double size = 64,
    double iconSize = 28,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
