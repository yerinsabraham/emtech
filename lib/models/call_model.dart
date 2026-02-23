import 'package:cloud_firestore/cloud_firestore.dart';

enum CallStatus {
  ringing,
  answered,
  ended,
  missed,
  rejected
}

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String receiverId; // Admin ID
  final String channelName;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? duration; // Duration in seconds

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.receiverId,
    required this.channelName,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.duration,
  });

  factory CallModel.fromMap(Map<String, dynamic> map, String callId) {
    return CallModel(
      callId: callId,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhotoUrl: map['callerPhotoUrl'],
      receiverId: map['receiverId'] ?? '',
      channelName: map['channelName'] ?? '',
      status: CallStatus.values.firstWhere(
        (e) => e.toString() == 'CallStatus.${map['status']}',
        orElse: () => CallStatus.ringing,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      answeredAt: map['answeredAt'] != null 
          ? (map['answeredAt'] as Timestamp).toDate() 
          : null,
      endedAt: map['endedAt'] != null 
          ? (map['endedAt'] as Timestamp).toDate() 
          : null,
      duration: map['duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverId': receiverId,
      'channelName': channelName,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'duration': duration,
    };
  }

  CallModel copyWith({
    CallStatus? status,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? duration,
  }) {
    return CallModel(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      receiverId: receiverId,
      channelName: channelName,
      status: status ?? this.status,
      createdAt: createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }
}
