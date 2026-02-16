import 'package:flutter/material.dart';

class AboutInfoDeskPage extends StatelessWidget {
  const AboutInfoDeskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'About EMTech',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'EMTech School',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Empowering the next generation of tech innovators',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Mission
          _buildSection(
            'Our Mission',
            'EMTech is committed to providing accessible, high-quality technology education to students worldwide. We believe in the power of blockchain technology and cryptocurrency to democratize learning and create new opportunities.',
            Icons.rocket_launch,
          ),

          // Vision
          _buildSection(
            'Our Vision',
            'To become the leading platform for blockchain-powered education, where students can learn, earn, and build their future in technology without financial barriers.',
            Icons.visibility,
          ),

          // What We Offer
          const SizedBox(height: 24),
          const Text(
            'What We Offer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Premium Courses',
            'Access to industry-leading courses in web development, mobile apps, AI, blockchain, and more.',
            Icons.workspace_premium,
            const Color(0xFF3B82F6),
          ),
          _buildFeatureCard(
            'EMC Token Economy',
            'Earn EMC tokens for completing tasks, staking for rewards, and use them to enroll in courses.',
            Icons.monetization_on,
            const Color(0xFFFBBF24),
          ),
          _buildFeatureCard(
            'Scholarship Program',
            'Pay only 30% deposit for full scholarships. Get your deposit back upon graduation!',
            Icons.emoji_events,
            const Color(0xFF10B981),
          ),
          _buildFeatureCard(
            'Student Loans',
            'Flexible loan options to help you access education now and pay later.',
            Icons.account_balance,
            const Color(0xFF8B5CF6),
          ),
          _buildFeatureCard(
            'Live Classes',
            'Interactive sessions with expert instructors and real-time collaboration.',
            Icons.video_call,
            const Color(0xFFEF4444),
          ),
          _buildFeatureCard(
            'Community Forum',
            'Connect with fellow students, share knowledge, and grow together.',
            Icons.forum,
            const Color(0xFFF59E0B),
          ),

          const SizedBox(height: 32),

          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
            ),
            child: Column(
              children: [
                const Text(
                  'Our Impact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('5,000+', 'Students'),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF1E2D4A),
                    ),
                    _buildStat('150+', 'Courses'),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF1E2D4A),
                    ),
                    _buildStat('50+', 'Instructors'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Core Values
          const Text(
            'Core Values',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildValueItem('💡 Innovation', 'Embracing cutting-edge technology'),
          _buildValueItem('🤝 Accessibility', 'Education for everyone'),
          _buildValueItem('🎯 Excellence', 'High-quality content and instruction'),
          _buildValueItem('🌍 Community', 'Building connections globally'),
          _buildValueItem('🔒 Transparency', 'Blockchain-based verification'),

          const SizedBox(height: 32),

          // Contact Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get in Touch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactItem(Icons.email, 'info@emtech.school'),
                _buildContactItem(Icons.language, 'www.emtech.school'),
                _buildContactItem(Icons.location_on, 'Global - Remote First'),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String description, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF3B82F6),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildValueItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.split(' ')[0],
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.substring(title.indexOf(' ') + 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
