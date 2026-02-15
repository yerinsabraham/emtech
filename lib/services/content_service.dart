import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/content_model.dart';
import 'notification_service.dart';

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Upload content
  Future<String> uploadContent({
    required String courseId,
    required String courseName,
    required String title,
    required String description,
    required ContentType type,
    required File file,
    required String uploadedById,
    required String uploadedByName,
    required String uploadedByRole, // 'admin' or 'lecturer'
    File? thumbnailFile,
  }) async {
    try {
      // Determine access level based on uploader role
      final accessLevel = uploadedByRole == 'admin'
          ? ContentAccessLevel.freemium
          : ContentAccessLevel.premium;

      // Upload main file
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'content/$courseId/$fileName';
      final ref = _storage.ref().child(filePath);
      
      final uploadTask = await ref.putFile(file);
      final fileUrl = await ref.getDownloadURL();
      final fileSizeBytes = (await file.length());
      
      // Upload thumbnail if provided
      String? thumbnailUrl;
      if (thumbnailFile != null) {
        final thumbFileName = 'thumb_$fileName';
        final thumbRef = _storage.ref().child('content/$courseId/$thumbFileName');
        await thumbRef.putFile(thumbnailFile);
        thumbnailUrl = await thumbRef.getDownloadURL();
      }

      final content = ContentModel(
        id: '',
        courseId: courseId,
        courseName: courseName,
        title: title,
        description: description,
        type: type,
        fileUrl: fileUrl,
        thumbnailUrl: thumbnailUrl,
        accessLevel: accessLevel,
        uploadedById: uploadedById,
        uploadedByName: uploadedByName,
        uploadedByRole: uploadedByRole,
        createdAt: DateTime.now(),
        fileSizeBytes: fileSizeBytes,
        mimeType: _getMimeType(file.path),
      );

      final docRef = await _firestore.collection('content').add(content.toFirestore());

      // Notify enrolled students about new content
      await _notificationService.notifyCourseStudents(
        courseId: courseId,
        title: 'New Content Available',
        message: '$uploadedByName uploaded "$title" in $courseName',
        type: 'content',
        actionUrl: '/content/${docRef.id}',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload content: $e');
    }
  }

  // Upload content from URL (for external links)
  Future<String> uploadContentFromUrl({
    required String courseId,
    required String courseName,
    required String title,
    required String description,
    required String url,
    required String uploadedById,
    required String uploadedByName,
    required String uploadedByRole,
  }) async {
    try {
      final accessLevel = uploadedByRole == 'admin'
          ? ContentAccessLevel.freemium
          : ContentAccessLevel.premium;

      final content = ContentModel(
        id: '',
        courseId: courseId,
        courseName: courseName,
        title: title,
        description: description,
        type: ContentType.link,
        fileUrl: url,
        accessLevel: accessLevel,
        uploadedById: uploadedById,
        uploadedByName: uploadedByName,
        uploadedByRole: uploadedByRole,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('content').add(content.toFirestore());

      // Notify enrolled students
      await _notificationService.notifyCourseStudents(
        courseId: courseId,
        title: 'New Resource Available',
        message: '$uploadedByName shared "$title" in $courseName',
        type: 'content',
        actionUrl: '/content/${docRef.id}',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload content: $e');
    }
  }

  // Get content by course
  Stream<List<ContentModel>> getContentByCourse(String courseId) {
    return _firestore
        .collection('content')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentModel.fromFirestore(doc))
            .toList());
  }

  // Get freemium content (accessible to all)
  Stream<List<ContentModel>> getFreemiumContent() {
    return _firestore
        .collection('content')
        .where('accessLevel', isEqualTo: 'freemium')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentModel.fromFirestore(doc))
            .toList());
  }

  // Get content by uploader
  Stream<List<ContentModel>> getContentByUploader(String uploaderId) {
    return _firestore
        .collection('content')
        .where('uploadedById', isEqualTo: uploaderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentModel.fromFirestore(doc))
            .toList());
  }

  // Increment view count
  Future<void> incrementViewCount(String contentId) async {
    try {
      await _firestore.collection('content').doc(contentId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to update view count: $e');
    }
  }

  // Increment download count
  Future<void> incrementDownloadCount(String contentId) async {
    try {
      await _firestore.collection('content').doc(contentId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to update download count: $e');
    }
  }

  // Delete content
  Future<void> deleteContent(String contentId) async {
    try {
      // Get content details to delete file from storage
      final contentDoc = await _firestore.collection('content').doc(contentId).get();
      if (contentDoc.exists) {
        final content = ContentModel.fromFirestore(contentDoc);
        
        // Delete file from storage if it's not an external link
        if (content.type != ContentType.link) {
          try {
            final ref = _storage.refFromURL(content.fileUrl);
            await ref.delete();
            
            // Delete thumbnail if exists
            if (content.thumbnailUrl != null) {
              final thumbRef = _storage.refFromURL(content.thumbnailUrl!);
              await thumbRef.delete();
            }
          } catch (e) {
            // Continue even if file deletion fails
          }
        }
      }

      // Delete Firestore document
      await _firestore.collection('content').doc(contentId).delete();
    } catch (e) {
      throw Exception('Failed to delete content: $e');
    }
  }

  // Update content
  Future<void> updateContent({
    required String contentId,
    String? title,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;

      if (updates.isNotEmpty) {
        await _firestore.collection('content').doc(contentId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update content: $e');
    }
  }

  // Helper method to determine MIME type
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mp3';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
