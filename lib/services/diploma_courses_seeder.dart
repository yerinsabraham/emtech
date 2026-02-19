import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

/// Service to seed diploma courses into Firebase Firestore
class DiplomaCoursesSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all 20 diploma courses to Firestore
  Future<void> seedDiplomaCourses() async {
    final courses = _getDiplomaCourses();
    
    try {
      for (final course in courses) {
        await _firestore.collection('courses').add(course.toMap());
      }
      print('✅ Successfully seeded ${courses.length} diploma courses');
    } catch (e) {
      print('❌ Error seeding courses: $e');
      rethrow;
    }
  }

  /// Check if diploma courses already exist
  Future<bool> diplomaCoursesExist() async {
    final snapshot = await _firestore
        .collection('courses')
        .where('category', isEqualTo: 'Diploma')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Clear all existing diploma courses (use with caution)
  Future<void> clearDiplomaCourses() async {
    final snapshot = await _firestore
        .collection('courses')
        .where('category', isEqualTo: 'Diploma')
        .get();
    
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    print('🗑️ Cleared ${snapshot.docs.length} diploma courses');
  }

  /// Get all 20 diploma courses
  List<CourseModel> _getDiplomaCourses() {
    final now = DateTime.now();
    
    return [
      CourseModel(
        id: '',
        title: 'Diploma in Artificial Intelligence Fundamentals',
        description: 'Simple introduction to AI, what it is, what it can do. Learn core AI concepts, applications, and real-world use cases. Perfect for beginners looking to understand the basics of AI technology.',
        instructor: 'Dr. Adewale Johnson',
        priceEmc: 250,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400',
        modules: [
          'Introduction to AI',
          'Machine Learning Basics',
          'AI Applications',
          'Ethics in AI',
          'Future of AI'
        ],
        duration: 120,
        createdAt: now.subtract(const Duration(days: 1)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in AI & Machine Learning for Business',
        description: 'How AI and ML are used in companies, decision-making, customer analytics. Learn to leverage AI tools for business intelligence, predictive analytics, and data-driven decisions.',
        instructor: 'Prof. Chiamaka Okonkwo',
        priceEmc: 300,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400',
        modules: [
          'Business Intelligence with AI',
          'Customer Analytics',
          'Predictive Models',
          'AI Strategy',
          'Case Studies'
        ],
        duration: 140,
        createdAt: now.subtract(const Duration(days: 2)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Robotics & Automation',
        description: 'Build and understand simple robots, sensors, actuators, robot behaviours. Hands-on experience with robotics hardware, programming, and control systems.',
        instructor: 'Eng. Oluwaseun Adebayo',
        priceEmc: 350,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=400',
        modules: [
          'Robotics Fundamentals',
          'Sensors and Actuators',
          'Robot Programming',
          'Control Systems',
          'Practical Projects'
        ],
        duration: 160,
        createdAt: now.subtract(const Duration(days: 3)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Smart Contracts & Blockchain Development',
        description: 'How to code smart contracts, how blockchains work, token creation. Master Solidity programming, deploy smart contracts, and build decentralized applications.',
        instructor: 'Dr. Chinedu Eze',
        priceEmc: 400,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=400',
        modules: [
          'Blockchain Fundamentals',
          'Solidity Programming',
          'Smart Contract Development',
          'Token Standards (ERC-20, ERC-721)',
          'DApp Deployment'
        ],
        duration: 150,
        createdAt: now.subtract(const Duration(days: 4)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Decentralised Finance (DeFi) & Web3',
        description: 'FinTech meets blockchain: staking, yield, decentralized apps, Web3 wallets. Learn about DeFi protocols, yield farming, liquidity pools, and Web3 development.',
        instructor: 'Amaka Nwankwo',
        priceEmc: 380,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1621761191319-c6fb62004040?w=400',
        modules: [
          'DeFi Fundamentals',
          'Staking and Yield Farming',
          'Liquidity Pools',
          'Web3 Wallets',
          'DeFi Security'
        ],
        duration: 130,
        createdAt: now.subtract(const Duration(days: 5)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Tech Media Production & AI Content Creation',
        description: 'Use AI tools to make tech-videos, content, media channels. Learn video production, content creation with AI tools like ChatGPT, DALL·E, and video editing software.',
        instructor: 'Tunde Bakare',
        priceEmc: 280,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
        modules: [
          'Video Production Basics',
          'AI Content Tools',
          'Scriptwriting with AI',
          'Video Editing',
          'Channel Management'
        ],
        duration: 120,
        createdAt: now.subtract(const Duration(days: 6)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Tech Journalism & Digital Broadcasting',
        description: 'Covering AI, blockchain, robotics: journalism, news-reporting, digital media. Learn to report on emerging technologies, conduct interviews, and produce tech news content.',
        instructor: 'Ngozi Okafor',
        priceEmc: 260,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400',
        modules: [
          'Tech Journalism Basics',
          'News Reporting',
          'Interview Techniques',
          'Digital Broadcasting',
          'Ethics in Tech Journalism'
        ],
        duration: 110,
        createdAt: now.subtract(const Duration(days: 7)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in AI Tools & Prompt Engineering',
        description: 'Teaching how to work with AI tools (ChatGPT, DALL·E, etc.), prompt design, content automation. Master the art of prompt engineering and AI tool optimization.',
        instructor: 'Dr. Biodun Alabi',
        priceEmc: 220,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1676911809746-a6992e57e19c?w=400',
        modules: [
          'AI Tools Overview',
          'Prompt Engineering',
          'Advanced Prompting Techniques',
          'Content Automation',
          'AI Workflow Optimization'
        ],
        duration: 100,
        createdAt: now.subtract(const Duration(days: 8)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Robotics + AI Integration',
        description: 'Combine robotics hardware with AI: vision, control, autonomous behaviours. Learn computer vision, AI-powered robotics, and autonomous system design.',
        instructor: 'Prof. Emeka Obi',
        priceEmc: 420,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1563207153-f403bf289096?w=400',
        modules: [
          'Computer Vision for Robotics',
          'AI Algorithms',
          'Autonomous Navigation',
          'Sensor Fusion',
          'Advanced Projects'
        ],
        duration: 180,
        createdAt: now.subtract(const Duration(days: 9)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Cybersecurity for Emerging Tech',
        description: 'Security aspects of AI, robotics and blockchain. Learn to secure AI systems, blockchain networks, and IoT devices against modern cyber threats.',
        instructor: 'Yemi Adeyemi',
        priceEmc: 350,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=400',
        modules: [
          'Cybersecurity Fundamentals',
          'AI Security',
          'Blockchain Security',
          'IoT Security',
          'Threat Analysis'
        ],
        duration: 140,
        createdAt: now.subtract(const Duration(days: 10)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Data Science & Analytics for Emerging Tech',
        description: 'Data cleaning, visualization, ML models for AI/Robotics/Web3 contexts. Master data science tools, statistical analysis, and machine learning applications.',
        instructor: 'Dr. Fatima Bello',
        priceEmc: 330,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
        modules: [
          'Data Science Fundamentals',
          'Data Cleaning',
          'Data Visualization',
          'ML for Emerging Tech',
          'Real-world Projects'
        ],
        duration: 150,
        createdAt: now.subtract(const Duration(days: 11)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in UI/UX & Product Design for Tech Startups',
        description: 'Design thinking, user experience for AI/robotics/blockchain products. Learn to design intuitive interfaces for emerging technology products.',
        instructor: 'Chioma Uzor',
        priceEmc: 270,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400',
        modules: [
          'Design Thinking',
          'User Research',
          'UI Design',
          'UX Principles',
          'Prototyping'
        ],
        duration: 120,
        createdAt: now.subtract(const Duration(days: 12)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in IoT & Embedded Systems for Smart Machines',
        description: 'Internet of Things hardware + sensors + robotics + connectivity. Build connected devices and learn embedded systems programming.',
        instructor: 'Eng. Kelechi Okoro',
        priceEmc: 360,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
        modules: [
          'IoT Fundamentals',
          'Embedded Systems',
          'Sensor Networks',
          'Connectivity Protocols',
          'Smart Machine Projects'
        ],
        duration: 160,
        createdAt: now.subtract(const Duration(days: 13)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Smart Cities & Automation Systems',
        description: 'How robotics, AI and blockchain come together to build smarter infrastructure. Design integrated systems for smart city applications.',
        instructor: 'Dr. Ibrahim Musa',
        priceEmc: 390,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400',
        modules: [
          'Smart Cities Overview',
          'Urban Infrastructure',
          'Automation Systems',
          'AI in Cities',
          'Implementation Strategy'
        ],
        duration: 140,
        createdAt: now.subtract(const Duration(days: 14)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Tokenomics & Blockchain Product Management',
        description: 'How to design token models, manage blockchain product launches, communities. Learn cryptocurrency economics and blockchain product strategy.',
        instructor: 'Aisha Abdullahi',
        priceEmc: 340,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1621761191319-c6fb62004040?w=400',
        modules: [
          'Tokenomics Fundamentals',
          'Token Design',
          'Product Management',
          'Community Building',
          'Launch Strategy'
        ],
        duration: 130,
        createdAt: now.subtract(const Duration(days: 15)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Generative AI & Digital Creativity',
        description: 'Use AI to generate art, music, design, media; monetize your creations. Master tools like Midjourney, Stable Diffusion, and AI music generators.',
        instructor: 'Femi Ogunleye',
        priceEmc: 290,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1686191128892-c0708e50bcbb?w=400',
        modules: [
          'Generative AI Basics',
          'AI Art Generation',
          'AI Music',
          'Creative Applications',
          'Monetization Strategies'
        ],
        duration: 110,
        createdAt: now.subtract(const Duration(days: 16)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Technology Entrepreneurship for Emerging Tech',
        description: 'Starting a tech-business in AI, robotics, blockchain: idea to MVP to fundraising. Learn startup fundamentals, pitch development, and funding strategies.',
        instructor: 'Dr. Bola Tinubu',
        priceEmc: 320,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=400',
        modules: [
          'Startup Fundamentals',
          'Idea Validation',
          'MVP Development',
          'Pitch Development',
          'Fundraising'
        ],
        duration: 125,
        createdAt: now.subtract(const Duration(days: 17)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in AI Ethics, Policy & Regulation',
        description: 'Understand regulation, governance of AI, robotics, blockchain especially in Africa. Learn about ethical AI development, policy frameworks, and compliance.',
        instructor: 'Prof. Grace Nnenna',
        priceEmc: 280,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400',
        modules: [
          'AI Ethics',
          'Policy Frameworks',
          'African Regulations',
          'Compliance',
          'Governance Models'
        ],
        duration: 115,
        createdAt: now.subtract(const Duration(days: 18)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Cloud & DevOps for Emerging Tech Infrastructure',
        description: 'Learn how to deploy AI/robotics/blockchain systems in cloud, DevOps. Master cloud platforms, CI/CD pipelines, and infrastructure automation.',
        instructor: 'Eng. Uche Nnamdi',
        priceEmc: 370,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
        modules: [
          'Cloud Fundamentals',
          'DevOps Practices',
          'CI/CD Pipelines',
          'Container Orchestration',
          'Infrastructure as Code'
        ],
        duration: 155,
        createdAt: now.subtract(const Duration(days: 19)),
        studentsEnrolled: 0,
      ),
      
      CourseModel(
        id: '',
        title: 'Diploma in Media & Digital Broadcast for Tech Communities',
        description: 'Running media channels, podcasts, broadcast shows on tech/crypto/AI. Learn digital media production, content strategy, and community engagement.',
        instructor: 'Tola Odunsi',
        priceEmc: 250,
        category: 'Diploma',
        thumbnailUrl: 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400',
        modules: [
          'Digital Media Basics',
          'Podcast Production',
          'Broadcast Techniques',
          'Content Strategy',
          'Community Building'
        ],
        duration: 105,
        createdAt: now.subtract(const Duration(days: 20)),
        studentsEnrolled: 0,
      ),
    ];
  }
}
