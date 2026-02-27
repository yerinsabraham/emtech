import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../config/home_design_tokens.dart';
import '../models/book_model.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/login_page.dart';
import '../widgets/app_page_header.dart';

class BookshopPage extends StatefulWidget {
  const BookshopPage({super.key});
  @override
  State<BookshopPage> createState() => _BookshopPageState();
}

class _BookshopPageState extends State<BookshopPage> {
  String _selectedCategory = 'All Books';
  static const _categories = ['All Books', 'Textbooks', 'Novels', 'Reference'];

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(HomeSpacing.s16),

              AppPageHeader(
                title: 'Bookshop',
                subtitle: 'Browse and purchase books',
                trailing: [
                  AppPageHeaderButton(
                    icon: Iconsax.search_normal,
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08),

              const Gap(HomeSpacing.s20),

              SizedBox(
                height: HomeSizes.chipHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const Gap(HomeSpacing.s8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _CategoryChip(
                      label: cat,
                      selected: cat == _selectedCategory,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ).animate(delay: (index * 60).ms).fadeIn(duration: 250.ms);
                  },
                ),
              ),

              const Gap(HomeSpacing.s20),

              Expanded(
                child: StreamBuilder<List<BookModel>>(
                  stream: firestoreService.getBooks(
                    category: _selectedCategory == 'All Books'
                        ? null
                        : _selectedCategory,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const AppEmptyState(
                        icon: Iconsax.book,
                        title: 'No books available',
                        subtitle: 'Check back later for new releases.',
                      );
                    }
                    final books = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: books.length,
                      itemBuilder: (context, index) =>
                          _BookCard(
                                book: books[index],
                                onPurchase: () => _handlePurchase(books[index]),
                              )
                              .animate(delay: (index * 50).ms)
                              .fadeIn(duration: 300.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                curve: Curves.easeOut,
                              ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BookModel book) async {
    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const LoginPage(),
        ),
      );
      return;
    }
    // Capture context-dependent refs before any await
    final messenger = ScaffoldMessenger.of(context);
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.user!.uid;

    final success = await authService.spendEmcTokens(
      book.priceEmc,
      'Purchased: ${book.title}',
    );
    if (success) {
      await firestoreService.addTransaction(
        TransactionModel(
          id: '',
          userId: userId,
          type: 'spend',
          amount: book.priceEmc,
          description: 'Purchased: ${book.title}',
          relatedId: book.id,
          createdAt: DateTime.now(),
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('${book.title} purchased!'),
          backgroundColor: AppColors.teal,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Insufficient EMC tokens'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: HomeSpacing.s16,
          vertical: HomeSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(HomeRadius.r20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.stroke,
            width: HomeEffects.borderWidth,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: AppColors.shadowPrimary,
                    blurRadius: HomeEffects.softElevation,
                    offset: HomeEffects.shadowOffset,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onPurchase});
  final BookModel book;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(HomeRadius.r24),
        border: Border.all(
          color: AppColors.stroke,
          width: HomeEffects.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: HomeEffects.softElevation,
            offset: HomeEffects.shadowOffset,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPurchase,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primaryCard,
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.book_1,
                      color: AppColors.onPrimary,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(HomeSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: HomeSpacing.s8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentMuted,
                              borderRadius: BorderRadius.circular(
                                HomeRadius.r12,
                              ),
                            ),
                            child: Text(
                              '${book.priceEmc} EMC',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Iconsax.shopping_cart,
                            color: AppColors.primary,
                            size: HomeSizes.iconSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
