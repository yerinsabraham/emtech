import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveClassViewerPage extends StatefulWidget {
  final String liveClassId;

  const LiveClassViewerPage({
    super.key,
    required this.liveClassId,
  });

  @override
  State<LiveClassViewerPage> createState() => _LiveClassViewerPageState();
}

class _LiveClassViewerPageState extends State<LiveClassViewerPage> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLiveClass();
  }

  Future<void> _loadLiveClass() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('liveClasses')
          .doc(widget.liveClassId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Live class not found';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final youtubeVideoId = data['youtubeVideoId'] as String?;

      if (youtubeVideoId == null || youtubeVideoId.isEmpty) {
        setState(() {
          _error = 'Invalid YouTube URL';
          _isLoading = false;
        });
        return;
      }

      _controller = YoutubePlayerController(
        initialVideoId: youtubeVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          isLive: true,
          controlsVisibleAtStart: true,
          hideControls: false,
        ),
      );

      setState(() {
        _isLoading = false;
      });

      // Increment viewer count
      await FirebaseFirestore.instance
          .collection('liveClasses')
          .doc(widget.liveClassId)
          .update({
        'viewerCount': FieldValue.increment(1),
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading live class: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Live Class',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // YouTube Player
                    YoutubePlayer(
                      controller: _controller!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.red,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.red,
                        handleColor: Colors.redAccent,
                      ),
                      onReady: () {
                        debugPrint('YouTube player ready');
                      },
                    ),
                    // Live Class Details
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('liveClasses')
                            .doc(widget.liveClassId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            );
                          }

                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'Live Class';
                          final description = data['description'] ?? '';
                          final instructorName = data['instructorName'] ?? 'Instructor';
                          final courseName = data['courseName'] ?? 'Course';
                          final viewerCount = data['viewerCount'] ?? 0;
                          final status = data['status'] ?? 'scheduled';

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Badge
                                if (status == 'live')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$viewerCount watching',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                // Title
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Course Name
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111C2F),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    courseName,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Instructor
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFF1A2940),
                                      radius: 20,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          instructorName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Text(
                                          'Instructor',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Description
                                const Text(
                                  'About this class',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
