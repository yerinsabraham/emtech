import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/staking_model.dart';
import '../../models/user_model.dart';
import '../../services/staking_service.dart';
import '../../services/reward_service.dart';
import '../../config/mock_data_config.dart';
import '../../services/mock_data_service.dart';
import '../payment/payment_selection_page.dart';

class EnhancedWalletPage extends StatefulWidget {
  final UserModel userModel;

  const EnhancedWalletPage({super.key, required this.userModel});

  @override
  State<EnhancedWalletPage> createState() => _EnhancedWalletPageState();
}

class _EnhancedWalletPageState extends State<EnhancedWalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StakingService _stakingService = StakingService();
  final RewardService _rewardService = RewardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        title: const Text('EMC Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Staking'),
            Tab(text: 'Rewards'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStakingTab(),
          _buildRewardsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final availableEMC = widget.userModel.availableEMC;
    final stakedEMC = widget.userModel.stakedEMC;
    final unredeemedEMC = widget.userModel.unredeemedEMC;
    final totalBalance = widget.userModel.emcBalance.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2744), Color(0xFF0F1B30)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total EMC Balance',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalBalance.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'EMC',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Cards
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Available',
                  availableEMC,
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard(
                  'Staked',
                  stakedEMC,
                  Icons.lock,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Unredeemed',
                  unredeemedEMC,
                  Icons.card_giftcard,
                  Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<double>(
                  future: _stakingService.calculateCurrentRewards(widget.userModel.uid),
                  builder: (context, snapshot) {
                    final rewards = snapshot.data ?? 0;
                    return _buildBalanceCard(
                      'Staking Rewards',
                      rewards,
                      Icons.trending_up,
                      Colors.purple,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'Stake EMC',
                Icons.add_circle,
                () => _showStakeDialog(),
              ),
              _buildActionButton(
                'Buy EMC',
                Icons.add_shopping_cart,
                () => _showBuyEmcSheet(context),
              ),
              _buildActionButton(
                'Redeem',
                Icons.redeem,
                () => _redeemUnredeemedRewards(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            amount.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ── Buy EMC ────────────────────────────────────────────────────────────────

  void _showBuyEmcSheet(BuildContext context) {
    /// EMC packages: {label, emcAmount, priceNgn}
    const packages = [
      {'label': 'Starter', 'emc': 500, 'ngn': 500},
      {'label': 'Standard', 'emc': 1000, 'ngn': 1000},
      {'label': 'Pro', 'emc': 5000, 'ngn': 5000},
      {'label': 'Elite', 'emc': 10000, 'ngn': 10000},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buy EMC Tokens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '1 NGN = 1 EMC  •  Powered by Paystack',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ...packages.map(
              (pkg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEmcPackageTile(
                  context,
                  label: pkg['label'] as String,
                  emcAmount: pkg['emc'] as int,
                  priceNgn: pkg['ngn'] as int,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmcPackageTile(
    BuildContext context, {
    required String label,
    required int emcAmount,
    required int priceNgn,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSelectionPage(
              itemType: 'wallet',
              itemId: 'wallet_topup_${emcAmount}emc',
              itemName: '$emcAmount EMC Top-up',
              amount: emcAmount.toDouble(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2744),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3F5F)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00C2FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.token, color: Color(0xFF00C2FF), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emcAmount EMC  •  $label',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₦$priceNgn',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildStakingTab() {
    // Use mock data if enabled
    if (MockDataConfig.isEnabledFor('staking')) {
      final mockStakes = MockDataService.getMockStakingData();
      
      if (mockStakes.isEmpty) {
        return _buildEmptyStakingState();
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockStakes.length,
        itemBuilder: (context, index) {
          final stake = mockStakes[index];
          final stakedAmount = (stake['stakedAmount'] as num).toDouble();
          final tier = stake['tier'] as String;
          final apyPercentage = stake['apyPercentage'] as String;
          final durationDays = stake['durationDays'] as int;
          final isActive = stake['isActive'] as bool;
          
          // Calculate rewards based on tier APY
          double apy = 0.05; // Default 5%
          if (tier == 'Silver') apy = 0.10;
          else if (tier == 'Gold') apy = 0.15;
          else if (tier == 'Platinum') apy = 0.20;
          
          final rewards = (stakedAmount * apy * durationDays) / 365;
          
          return Card(
            color: const Color(0xFF1A2744),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$tier Tier 🏆',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Unstaked',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStakeInfo('Staked Amount', '${stakedAmount.toStringAsFixed(0)} EMC'),
                  _buildStakeInfo('Duration', '$durationDays days'),
                  _buildStakeInfo('APY', apyPercentage),
                  _buildStakeInfo('Rewards', '${rewards.toStringAsFixed(2)} EMC'),
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mock staking - unstaking disabled in demo mode')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Unstake (Demo)'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }
    
    // Live data from Firebase
    return StreamBuilder<List<StakingModel>>(
      stream: _stakingService.getUserStakes(widget.userModel.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stakes = snapshot.data ?? [];

        if (stakes.isEmpty) {
          return _buildEmptyStakingState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stakes.length,
          itemBuilder: (context, index) {
            final stake = stakes[index];
            final durationDays = stake.isActive ? stake.durationDays : stake.stakingDurationDays;
            final rewards = StakingModel.calculateRewards(
              stake.stakedAmount,
              stake.tier,
              durationDays,
            );

            return Card(
              color: const Color(0xFF1A2744),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stake.tierBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stake.isActive ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stake.isActive ? 'Active' : 'Unstaked',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStakeInfo('Staked Amount', '${stake.stakedAmount.toStringAsFixed(0)} EMC'),
                    _buildStakeInfo('Duration', '$durationDays days'),
                    _buildStakeInfo('APY', stake.apyPercentage),
                    _buildStakeInfo('Rewards', '${rewards.toStringAsFixed(2)} EMC'),
                    if (stake.isActive) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _unstakeEMC(stake.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('Unstake'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildEmptyStakingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_open, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No active stakes',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showStakeDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Start Staking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    // Use mock data if enabled
    if (MockDataConfig.isEnabledFor('rewards')) {
      final mockRewards = MockDataService.getMockRewardsData();
      
      if (mockRewards.isEmpty) {
        return const Center(
          child: Text(
            'No rewards yet',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockRewards.length,
        itemBuilder: (context, index) {
          final reward = mockRewards[index];
          final amount = (reward['amount'] as num).toDouble();
          final redeemed = reward['redeemed'] as bool;
          final type = reward['type'] as String;
          
          String typeLabel;
          switch (type) {
            case 'signup':
              typeLabel = 'SIGN-UP BONUS';
              break;
            case 'enrollment':
              typeLabel = 'COURSE ENROLLMENT';
              break;
            case 'grade':
              typeLabel = 'GRADE REWARD (${reward['grade']})';
              break;
            case 'daily_task':
              typeLabel = 'DAILY TASK';
              break;
            case 'staking':
              typeLabel = 'STAKING REWARD';
              break;
            default:
              typeLabel = type.toUpperCase();
          }

          return ListTile(
            leading: Icon(
              redeemed ? Icons.check_circle : Icons.pending,
              color: redeemed ? Colors.green : Colors.orange,
            ),
            title: Text(
              '${amount.toStringAsFixed(0)} EMC',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              typeLabel,
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Text(
              redeemed ? 'Redeemed' : 'Pending',
              style: TextStyle(
                color: redeemed ? Colors.green : Colors.orange,
              ),
            ),
          );
        },
      );
    }
    
    // Live data from Firebase
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _rewardService.getRewardHistory(widget.userModel.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = snapshot.data ?? [];

        if (rewards.isEmpty) {
          return const Center(
            child: Text(
              'No rewards yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            final amount = (reward['amount'] ?? 0).toDouble();
            final redeemed = reward['redeemed'] ?? false;
            final type = reward['type'] ?? '';

            return ListTile(
              leading: Icon(
                redeemed ? Icons.check_circle : Icons.pending,
                color: redeemed ? Colors.green : Colors.orange,
              ),
              title: Text(
                '${amount.toStringAsFixed(0)} EMC',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                type.toUpperCase(),
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: Text(
                redeemed ? 'Redeemed' : 'Pending',
                style: TextStyle(
                  color: redeemed ? Colors.green : Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    // Use mock data if enabled
    if (MockDataConfig.isEnabledFor('transactions')) {
      final mockTransactions = MockDataService.getMockTransactions();
      
      if (mockTransactions.isEmpty) {
        return const Center(
          child: Text(
            'No transaction history yet',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockTransactions.length,
        itemBuilder: (context, index) {
          final txn = mockTransactions[index];
          final type = txn['type'] as String;
          final amount = txn['amount'] as int;
          final description = txn['description'] as String;
          final createdAt = txn['createdAt'] as DateTime;
          
          final isEarned = type == 'earn';
          final isStake = type == 'stake';
          
          IconData icon;
          if (description.contains('Purchase') || description.contains('Enrolled')) {
            icon = Icons.shopping_bag_outlined;
          } else if (description.contains('Task')) {
            icon = Icons.task_alt;
          } else if (description.contains('Reward') || description.contains('Bonus')) {
            icon = Icons.card_giftcard;
          } else if (description.contains('Staking') || description.contains('Staked')) {
            icon = Icons.lock_outlined;
          } else if (description.contains('Grade')) {
            icon = Icons.emoji_events_outlined;
          } else {
            icon = isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline;
          }
          
          Color amountColor;
          String amountText;
          if (isStake) {
            amountColor = Colors.blue;
            amountText = '🔒 ${amount.toStringAsFixed(0)} EMC';
          } else if (isEarned) {
            amountColor = const Color(0xFF4CAF50);
            amountText = '+${amount.toStringAsFixed(0)} EMC';
          } else {
            amountColor = const Color(0xFFFF5252);
            amountText = '-${amount.toStringAsFixed(0)} EMC';
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2744),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A3F5F).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1827),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white54,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(createdAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amountText,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    
    // Live data from Firebase - to be implemented
    return const Center(
      child: Text(
        'Transaction history coming soon',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showStakeDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        title: const Text('Stake EMC', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount to Stake',
                labelStyle: TextStyle(color: Colors.white54),
                suffixText: 'EMC',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Minimum: 1,000 EMC\n\nStaking Tiers:\n• Bronze: 1K-5K (5% APY)\n• Silver: 5K-20K (10% APY)\n• Gold: 20K-50K (15% APY)\n• Platinum: 50K+ (20% APY)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount < 1000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimum stake is 1,000 EMC')),
                );
                return;
              }

              try {
                await _stakingService.stakeEMC(
                  userId: widget.userModel.uid,
                  userName: widget.userModel.name,
                  amount: amount,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully staked EMC!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text('Stake'),
          ),
        ],
      ),
    );
  }

  Future<void> _unstakeEMC(String stakingId) async {
    try {
      await _stakingService.unstakeEMC(
        stakingId: stakingId,
        userId: widget.userModel.uid,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully unstaked EMC!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _redeemUnredeemedRewards() async {
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('rewards')
          .where('userId', isEqualTo: widget.userModel.uid)
          .where('redeemed', isEqualTo: false)
          .where('type', isEqualTo: 'enrollment')
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pending rewards to redeem')),
          );
        }
        return;
      }

      final courseIds = snap.docs
          .map((d) => (d.data()['courseId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final courseId in courseIds) {
        await _rewardService.redeemCourseCompletionRewards(
          userId: widget.userModel.uid,
          courseId: courseId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rewards redeemed! EMC added to your balance.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
