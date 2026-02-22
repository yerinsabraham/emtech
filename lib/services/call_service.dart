import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/call_model.dart';
import '../config/agora_config.dart';

class CallService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RtcEngine? _agoraEngine;
  CallModel? _currentCall;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  CallModel? get currentCall => _currentCall;
  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  /// Initialize Agora Engine
  Future<void> initializeAgora() async {
    if (!AgoraConfig.isConfigured) {
      debugPrint('⚠️ Agora not configured. Please add your App ID.');
      return;
    }

    try {
      // Request permissions
      await _requestPermissions();

      // Create Agora engine
      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set up event handlers
      _agoraEngine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Successfully joined channel: ${connection.channelId}');
            _isInCall = true;
            notifyListeners();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 User joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('👋 User left: $remoteUid');
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('📞 Left channel');
            _isInCall = false;
            notifyListeners();
          },
        ),
      );

      // Enable audio
      await _agoraEngine!.enableAudio();
      debugPrint('✅ Agora Engine initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Agora: $e');
    }
  }

  /// Request microphone permissions
  Future<bool> _requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    return micStatus.isGranted;
  }

  /// Initiate a call to support (from user side)
  Future<CallModel?> initiateCall({
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
  }) async {
    try {
      if (!AgoraConfig.isConfigured) {
        throw Exception('Agora not configured');
      }

      // Get the first admin user as the receiver
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        throw Exception('No admin available');
      }

      final adminId = adminQuery.docs.first.id;
      final channelName = '${AgoraConfig.supportChannelPrefix}${DateTime.now().millisecondsSinceEpoch}';

      // Create call document in Firestore
      final callRef = _firestore.collection('calls').doc();
      final call = CallModel(
        callId: callRef.id,
        callerId: callerId,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverId: adminId,
        channelName: channelName,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
      );

      await callRef.set(call.toMap());
      _currentCall = call;
      notifyListeners();

      debugPrint('✅ Call initiated: ${call.callId}');
      return call;
    } catch (e) {
      debugPrint('❌ Failed to initiate call: $e');
      return null;
    }
  }

  /// Join a call channel
  Future<void> joinCall(String channelName, int uid) async {
    try {
      if (_agoraEngine == null) {
        await initializeAgora();
      }

      if (_agoraEngine == null) {
        throw Exception('Agora engine not initialized');
      }

      // Generate token from Firebase Cloud Function (production)
      // Falls back to local token (development)
      String? token = await _generateToken(channelName, uid);

      // Join the channel
      await _agoraEngine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      debugPrint('✅ Joined channel: $channelName');
    } catch (e) {
      debugPrint('❌ Failed to join channel: $e');
      rethrow;
    }
  }

  /// Generate Agora token from Firebase Cloud Function or local config
  Future<String?> _generateToken(String channelName, int uid) async {
    try {
      // Try to get token from Firebase Cloud Function (production)
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('generateAgoraToken').call({
        'channelName': channelName,
        'uid': uid,
        'role': 'publisher',
      });

      debugPrint('✅ Token generated from Cloud Function');
      return result.data['token'] as String;
    } catch (e) {
      debugPrint('⚠️ Cloud Function not available, trying local token: $e');
      
      // Fall back to local token (development)
      if (AgoraConfig.tempToken.isNotEmpty && 
          AgoraConfig.tempToken != 'YOUR_TEMPORARY_TOKEN_HERE') {
        debugPrint('✅ Using local temp token');
        return AgoraConfig.tempToken;
      }
      
      // If no token available, return null (works only with APP ID only mode)
      debugPrint('⚠️ No token available, using APP ID only mode');
      return null;
    }
  }

  /// Answer an incoming call (admin side)
  Future<void> answerCall(String callId) async {
    try {
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      if (!callDoc.exists) {
        throw Exception('Call not found');
      }

      final call = CallModel.fromMap(callDoc.data()!, callId);
      _currentCall = call;

      // Update call status to answered
      await _firestore.collection('calls').doc(callId).update({
        'status': CallStatus.answered.toString().split('.').last,
        'answeredAt': Timestamp.now(),
      });

      notifyListeners();
      debugPrint('✅ Call answered: $callId');
    } catch (e) {
      debugPrint('❌ Failed to answer call: $e');
      rethrow;
    }
  }

  /// Reject a call (admin side)
  Future<void> rejectCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': CallStatus.rejected.toString().split('.').last,
        'endedAt': Timestamp.now(),
      });

      debugPrint('✅ Call rejected: $callId');
    } catch (e) {
      debugPrint('❌ Failed to reject call: $e');
    }
  }

  /// End the current call
  Future<void> endCall() async {
    try {
      if (_currentCall == null) return;

      // Leave the Agora channel
      await _agoraEngine?.leaveChannel();

      // Calculate duration if call was answered
      int? duration;
      if (_currentCall!.answeredAt != null) {
        duration = DateTime.now().difference(_currentCall!.answeredAt!).inSeconds;
      }

      // Update call status in Firestore
      await _firestore.collection('calls').doc(_currentCall!.callId).update({
        'status': CallStatus.ended.toString().split('.').last,
        'endedAt': Timestamp.now(),
        'duration': duration,
      });

      _currentCall = null;
      _isInCall = false;
      _isMuted = false;
      _isSpeakerOn = false;
      notifyListeners();

      debugPrint('✅ Call ended');
    } catch (e) {
      debugPrint('❌ Failed to end call: $e');
    }
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _agoraEngine?.muteLocalAudioStream(_isMuted);
      notifyListeners();
      debugPrint('🔇 Mute toggled: $_isMuted');
    } catch (e) {
      debugPrint('❌ Failed to toggle mute: $e');
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _agoraEngine?.setEnableSpeakerphone(_isSpeakerOn);
      notifyListeners();
      debugPrint('🔊 Speaker toggled: $_isSpeakerOn');
    } catch (e) {
      debugPrint('❌ Failed to toggle speaker: $e');
    }
  }

  /// Listen to incoming calls (for admin)
  Stream<List<CallModel>> listenToIncomingCalls(String adminId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: adminId)
        .where('status', isEqualTo: CallStatus.ringing.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get call history
  Future<List<CallModel>> getCallHistory(String userId, {bool isAdmin = false}) async {
    try {
      Query query = _firestore.collection('calls');
      
      if (isAdmin) {
        query = query.where('receiverId', isEqualTo: userId);
      } else {
        query = query.where('callerId', isEqualTo: userId);
      }
      
      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => CallModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get call history: $e');
      return [];
    }
  }

  /// Dispose Agora engine
  Future<void> disposeAgora() async {
    try {
      await _agoraEngine?.leaveChannel();
      await _agoraEngine?.release();
      _agoraEngine = null;
      debugPrint('✅ Agora Engine disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose Agora: $e');
    }
  }

  @override
  void dispose() {
    disposeAgora();
    super.dispose();
  }
}
