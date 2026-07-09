import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/app_header.dart';
import 'products_provider.dart';
import '../../models/product.dart';
import '../../core/widgets/skeleton_widgets.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _selectedCategory = 'All';
  final _categories = ['All', 'Gold', 'Silver', 'Platinum', 'Diamond'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding > 0 ? topPadding + 20 : 20),

          // ── Top Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/more');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Product Catalog',
                    style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchBarWidget(
              controller: _searchController,
              hint: 'Search by name, code, or category..',
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.toLowerCase().trim();
                });
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

          const SizedBox(height: 16),

          // ── Category Chips ──
          _buildCategoryChips()
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 16),

          // ── Product List ──
          Expanded(
            child: productsState.when(
              data: (productsList) {
                // Apply chip filter
                var filtered = productsList;
                if (_selectedCategory != 'All') {
                  filtered = filtered
                      .where((p) => p.category.toUpperCase() == _selectedCategory.toUpperCase())
                      .toList();
                }

                // Apply text search
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((p) {
                    final nameMatch = p.name.toLowerCase().contains(_searchQuery);
                    final codeMatch = (p.serialNumber ?? p.huidNumber ?? p.id ?? '').toLowerCase().contains(_searchQuery);
                    final catMatch = p.category.toLowerCase().contains(_searchQuery);
                    return nameMatch || codeMatch || catMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(productsProvider.notifier).loadProducts();
                    },
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: Text(
                          'No products found.',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productsProvider.notifier).loadProducts();
                  },
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                    final p = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onLongPress: () => _confirmDeleteProduct(context, ref, p),
                        child: GlassCard(
                          animationIndex: index,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          onTap: () => _showProductDetails(context, p),
                          child: Row(
                          children: [
                            // Product icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _categoryColor(p.category).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _categoryIcon(p.category),
                                color: _categoryColor(p.category),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: AppTextStyles.cardTitle),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'S/N: ${p.serialNumber ?? 'N/A'}${p.huidNumber != null && p.huidNumber!.isNotEmpty ? " | HUID: ${p.huidNumber}" : ""}',
                                        style: AppTextStyles.cardSubtitle,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _categoryColor(p.category)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.purity,
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: _categoryColor(p.category),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p.weight.toStringAsFixed(2)} g',
                                  style: AppTextStyles.amountSm.copyWith(
                                    color: AppColors.onBackground,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: p.stockUnits > 3
                                            ? AppColors.success
                                            : p.stockUnits > 0
                                                ? AppColors.warning
                                                : AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${p.stockUnits} in stock',
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onSurfaceMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                             Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.onSurfaceDim,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  },
                ),
              );
            },
              loading: () => const SkeletonList(
                type: SkeletonType.product,
                count: 6,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              ),
              error: (err, _) => Center(child: Text('Error loading products: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: () => context.push('/products/add'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.black),
        ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 400.ms,
              delay: 300.ms,
              curve: Curves.elasticOut,
            ),
      ),
    );
  }
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.glassBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                cat,
                style: AppTextStyles.labelMd.copyWith(
                  color: isSelected
                      ? Colors.black
                      : AppColors.onSurfaceMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side:  BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Delete Product',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
          ),
          content: Text(
            'Are you sure you want to delete product "${product.name}" (S/N: ${product.serialNumber ?? 'N/A'})?',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (product.id != null) {
                  await ref.read(productsProvider.notifier).deleteProduct(product.id!);
                }
              },
              child: Text('Delete', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product p) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
                      ),
                    ),
                    IconButton(
                      icon:  Icon(Icons.edit_rounded, color: AppColors.primary),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/products/edit', extra: p);
                      },
                    ),
                    IconButton(
                      icon:  Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteProduct(context, ref, p);
                      },
                    ),
                    IconButton(
                      icon:  Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                _detailRow('Serial Number', p.serialNumber ?? 'N/A'),
                _detailRow('HUID Number', p.huidNumber ?? 'No HUID'),
                _detailRow('Category', p.category),
                _detailRow('Purity', p.purity),
                _detailRow('HSN Code', p.hsnCode),
                if (p.serialNumber != null && p.serialNumber!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: p.serialNumber!,
                        width: 200,
                        height: 70,
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _detailRow('Weight (g)', '${p.weight.toStringAsFixed(3)} g'),
                _detailRow('Stock units', '${p.stockUnits} units'),
                if (p.stoneType != null && p.stoneType != 'NONE') ...[
                  _detailRow('Stone Type', p.stoneType!),
                  _detailRow('Stone Weight (g)', '${p.stoneWeight.toStringAsFixed(3)} g'),
                  _detailRow('Stone Value', '₹${p.stoneValue.toStringAsFixed(0)}'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted)),
          Text(value, style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'GOLD':
        return AppColors.primary;
      case 'SILVER':
        return AppColors.tierSilver;
      case 'PLATINUM':
        return const Color(0xFFB0C4DE);
      case 'DIAMOND':
        return const Color(0xFF87CEEB);
      default:
        return AppColors.onSurfaceMuted;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'GOLD':
        return Icons.auto_awesome_rounded;
      case 'SILVER':
        return Icons.circle_outlined;
      case 'PLATINUM':
        return Icons.hexagon_outlined;
      case 'DIAMOND':
        return Icons.diamond_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
