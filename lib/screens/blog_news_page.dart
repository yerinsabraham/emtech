import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/blog_post_model.dart';
import '../services/mock_data_service.dart';

class BlogNewsPage extends StatefulWidget {
  const BlogNewsPage({super.key});

  @override
  State<BlogNewsPage> createState() => _BlogNewsPageState();
}

class _BlogNewsPageState extends State<BlogNewsPage> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final posts = MockDataService.getMockBlogPosts();
    final filteredPosts = posts.where((post) {
      if (_selectedCategory != 'all' && post.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    // Sort by date
    filteredPosts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Blog & News',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 18),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _buildCategoryChip('All', 'all'),
                _buildCategoryChip('News', 'news'),
                _buildCategoryChip('Tutorials', 'tutorial'),
                _buildCategoryChip('Announcements', 'announcement'),
              ],
            ),
          ),

          // Blog Posts List
          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(
                    child: Text(
                      'No posts available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Featured post (big card)
                        return _buildFeaturedPostCard(filteredPosts[index]);
                      }
                      return _buildBlogPostCard(filteredPosts[index]);
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

  Widget _buildFeaturedPostCard(BlogPostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPostDetails(post),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (post.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFF1E2D4A),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.white24,
                            size: 48,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(post.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.category.toUpperCase(),
                        style: TextStyle(
                          color: _getCategoryColor(post.category),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Excerpt
                    Text(
                      post.excerpt,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Meta
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white38,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          post.author,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          color: Colors.white38,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.readTimeMinutes} min read',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d, yyyy').format(post.publishedAt),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlogPostCard(BlogPostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPostDetails(post),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                if (post.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFF1E2D4A),
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.article,
                            color: Colors.white24,
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(post.category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.category.toUpperCase(),
                          style: TextStyle(
                            color: _getCategoryColor(post.category),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        post.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Excerpt
                      Text(
                        post.excerpt,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Meta
                      Row(
                        children: [
                          Text(
                            post.author,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: const TextStyle(color: Colors.white24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d').format(post.publishedAt),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'news':
        return const Color(0xFF3B82F6);
      case 'tutorial':
        return const Color(0xFF10B981);
      case 'announcement':
        return const Color(0xFFFBBF24);
      default:
        return Colors.grey;
    }
  }

  void _showPostDetails(BlogPostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogPostDetailPage(post: post),
      ),
    );
  }
}

// Blog Post Detail Page
class BlogPostDetailPage extends StatelessWidget {
  final BlogPostModel post;

  const BlogPostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF0B1120),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: post.imageUrl != null
                  ? Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1E2D4A),
                          child: const Center(
                            child: Icon(
                              Icons.article,
                              color: Colors.white24,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF1E2D4A),
                      child: const Center(
                        child: Icon(
                          Icons.article,
                          color: Colors.white24,
                          size: 64,
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(post.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.category.toUpperCase(),
                      style: TextStyle(
                        color: _getCategoryColor(post.category),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF3B82F6),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(post.publishedAt),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: const TextStyle(color: Colors.white38),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${post.readTimeMinutes} min read',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Excerpt
                  Text(
                    post.excerpt,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const Divider(color: Color(0xFF1E2D4A)),
                  const SizedBox(height: 24),

                  // Content
                  Text(
                    post.content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),

                  // Tags
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2D4A).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'news':
        return const Color(0xFF3B82F6);
      case 'tutorial':
        return const Color(0xFF10B981);
      case 'announcement':
        return const Color(0xFFFBBF24);
      default:
        return Colors.grey;
    }
  }
}
