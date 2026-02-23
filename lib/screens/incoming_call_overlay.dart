import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import '../services/auth_service.dart';
import 'call_screen.dart';

class IncomingCallOverlay extends StatelessWidget {
  final CallModel call;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    super.key,
    required this.call,
    required this.onDismiss,
  });

  Future<void> _answerCall(BuildContext context) async {
    final authService = context.read<AuthService>();
    
    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          call: call,
          isOutgoing: false,
          currentUserId: authService.userModel!.uid,
          currentUserName: authService.userModel!.name,
        ),
      ),
    ).then((_) => onDismiss());
  }

  Future<void> _rejectCall(BuildContext context) async {
    final callService = context.read<CallService>();
    await callService.rejectCall(call.callId);
    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Caller avatar
              Container(
                width: 100,
                height: 100,
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
                child: call.callerPhotoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          call.callerPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(height: 24),

              // Caller name
              Text(
                call.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Call status
              const Text(
                'Incoming support call...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.red,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => _rejectCall(context),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Accept button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.green,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => _answerCall(context),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        call.callerName.isNotEmpty ? call.callerName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget to listen for incoming calls and show overlay
class IncomingCallListener extends StatefulWidget {
  final Widget child;

  const IncomingCallListener({
    super.key,
    required this.child,
  });

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  OverlayEntry? _overlayEntry;
  CallModel? _currentIncomingCall;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final callService = context.watch<CallService>();

    // Only listen for incoming calls if user is an admin and not currently in a call
    if (authService.userModel?.role == 'admin' && !callService.isInCall) {
      return StreamBuilder<List<CallModel>>(
        stream: callService.listenToIncomingCalls(authService.userModel!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final incomingCall = snapshot.data!.first;
            
            // Show overlay if not already shown or if it's a different call
            if (_currentIncomingCall?.callId != incomingCall.callId) {
              _currentIncomingCall = incomingCall;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showIncomingCallOverlay(incomingCall);
              });
            }
          } else if (_overlayEntry != null) {
            // Remove overlay if no incoming calls
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _removeOverlay();
            });
          }

          return widget.child;
        },
      );
    }

    return widget.child;
  }

  void _showIncomingCallOverlay(CallModel call) {
    _removeOverlay(); // Remove any existing overlay first

    _overlayEntry = OverlayEntry(
      builder: (context) => IncomingCallOverlay(
        call: call,
        onDismiss: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentIncomingCall = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}
