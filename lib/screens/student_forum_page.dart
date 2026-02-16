import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forum_post_model.dart';
import '../services/mock_data_service.dart';

class StudentForumPage extends StatefulWidget {
  const StudentForumPage({super.key});

  @override
  State<StudentForumPage> createState() => _StudentForumPageState();
}

class _StudentForumPageState extends State<StudentForumPage> {
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = MockDataService.getMockForumPosts();
    final filteredPosts = posts.where((post) {
      if (_selectedCategory != 'all' && post.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    // Sort: pinned first, then by date
    filteredPosts.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Student Forum',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create new post - Coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF111C2F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Filter
          Container(
            height: 45,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _buildCategoryChip('All', 'all'),
                _buildCategoryChip('Questions', 'question'),
                _buildCategoryChip('Discussions', 'discussion'),
                _buildCategoryChip('Announcements', 'announcement'),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(
                    child: Text(
                      'No posts yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      return _buildForumPostCard(filteredPosts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
        backgroundColor: const Color(0xFF111C2F),
        selectedColor: const Color(0xFF3B82F6),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E2D4A),
        ),
      ),
    );
  }

  Widget _buildForumPostCard(ForumPostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: post.isPinned 
              ? const Color(0xFFFBBF24).withOpacity(0.3)
              : const Color(0xFF1E2D4A),
          width: post.isPinned ? 1.5 : 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPostDetails(post);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author & Category
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        post.authorName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (post.isPinned) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.push_pin,
                                  color: Color(0xFFFBBF24),
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatTimeAgo(post.createdAt),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCategoryBadge(post.category),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Content Preview
                Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Tags
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2D4A).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    _buildStat(Icons.thumb_up_outlined, post.likes.toString()),
                    const SizedBox(width: 16),
                    _buildStat(Icons.comment_outlined, post.replies.toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    String label;

    switch (category) {
      case 'question':
        color = const Color(0xFF3B82F6);
        label = 'Q';
        break;
      case 'announcement':
        color = const Color(0xFFFBBF24);
        label = 'A';
        break;
      default:
        color = const Color(0xFF8B5CF6);
        label = 'D';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showPostDetails(ForumPostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C2F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            Text(
              post.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Author Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    post.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reply feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.comment),
                    label: const Text('Reply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_outlined),
                  color: Colors.white70,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2D4A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
