import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';

class ContentViewerPage extends StatefulWidget {
  final ContentModel content;

  const ContentViewerPage({super.key, required this.content});

  @override
  State<ContentViewerPage> createState() => _ContentViewerPageState();
}

class _ContentViewerPageState extends State<ContentViewerPage> {
  YoutubePlayerController? _ytController;
  bool _isLoadingExternal = false;

  @override
  void initState() {
    super.initState();
    ContentService().incrementViewCount(widget.content.id);
    _initViewer();
  }

  void _initViewer() {
    final content = widget.content;
    if (content.type == ContentType.video) {
      final videoId = YoutubePlayer.convertUrlToId(content.fileUrl);
      if (videoId != null) {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            disableDragSeek: false,
            loop: false,
            enableCaption: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _openExternal(String url) async {
    setState(() => _isLoadingExternal = true);
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      ContentService().incrementDownloadCount(widget.content.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingExternal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;

    return YoutubePlayerBuilder(
      player: _ytController != null
          ? YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
              progressColors: const ProgressBarColors(
                playedColor: Colors.blue,
                handleColor: Colors.blueAccent,
              ),
            )
          : YoutubePlayer(
              controller: YoutubePlayerController(initialVideoId: ''),
            ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF080C14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B1120),
            elevation: 0,
            title: Text(content.title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildBody(content, player),
        );
      },
    );
  }

  Widget _buildBody(ContentModel content, Widget player) {
    switch (content.type) {
      case ContentType.video:
        return _buildVideoView(content, player);
      case ContentType.document:
      case ContentType.presentation:
        return _buildDocumentView(content);
      case ContentType.link:
        return _buildLinkView(content);
      case ContentType.other:
        return _buildOtherView(content);
    }
  }

  // ── Video ──────────────────────────────────────────────────────────

  Widget _buildVideoView(ContentModel content, Widget player) {
    final isYouTube = _ytController != null;

    return Column(
      children: [
        if (isYouTube) player,
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If not a YouTube video, show open externally button
                if (!isYouTube)
                  _ExternalOpenButton(
                    label: 'Open Video',
                    icon: Icons.play_circle_fill,
                    color: Colors.red,
                    onTap: () => _openExternal(content.fileUrl),
                    isLoading: _isLoadingExternal,
                  ),
                const SizedBox(height: 20),
                _ContentInfoCard(content: content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Document / PDF ─────────────────────────────────────────────────

  Widget _buildDocumentView(ContentModel content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExternalOpenButton(
            label: content.type == ContentType.document
                ? 'Open Document'
                : 'Open Presentation',
            icon: content.type == ContentType.document
                ? Icons.description
                : Icons.slideshow,
            color: content.type == ContentType.document
                ? Colors.blue
                : Colors.orange,
            onTap: () => _openExternal(content.fileUrl),
            isLoading: _isLoadingExternal,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Opens in your device\'s default viewer',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          _ContentInfoCard(content: content),
        ],
      ),
    );
  }

  // ── Link ───────────────────────────────────────────────────────────

  Widget _buildLinkView(ContentModel content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.link, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text(
                  content.fileUrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingExternal
                        ? null
                        : () => _openExternal(content.fileUrl),
                    icon: _isLoadingExternal
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.open_in_new),
                    label: const Text('Open Link'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ContentInfoCard(content: content),
        ],
      ),
    );
  }

  // ── Other ──────────────────────────────────────────────────────────

  Widget _buildOtherView(ContentModel content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ExternalOpenButton(
            label: 'Open File',
            icon: Icons.insert_drive_file,
            color: Colors.grey,
            onTap: () => _openExternal(content.fileUrl),
            isLoading: _isLoadingExternal,
          ),
          const SizedBox(height: 24),
          _ContentInfoCard(content: content),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────

class _ExternalOpenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ExternalOpenButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Icon(icon),
        label: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ContentInfoCard extends StatelessWidget {
  final ContentModel content;

  const _ContentInfoCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                  label: content.courseName, icon: Icons.school),
              _TagChip(
                  label: 'By ${content.uploadedByName}',
                  icon: Icons.person),
              _TagChip(
                  label: '${content.viewCount} views',
                  icon: Icons.visibility),
              if (content.type != ContentType.link &&
                  content.fileSizeBytes > 0)
                _TagChip(
                    label: content.fileSizeFormatted,
                    icon: Icons.storage),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TagChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2940),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
