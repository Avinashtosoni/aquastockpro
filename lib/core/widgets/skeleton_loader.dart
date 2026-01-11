import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A shimmer effect widget for skeleton loading
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  /// Creates a circular skeleton (e.g., for avatars)
  const SkeletonLoader.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        isCircle = true;

  /// Creates a rectangular skeleton for text lines
  const SkeletonLoader.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  })  : borderRadius = 4,
        isCircle = false;

  /// Creates a card skeleton
  const SkeletonLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
  })  : borderRadius = 12,
        isCircle = false;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? AppColors.darkCardBackground 
        : Colors.grey.shade200;
    final highlightColor = isDark 
        ? AppColors.darkCardBorder 
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                (_animation.value + 2) / 4,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for product cards in POS grid
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            child: SkeletonLoader(
              borderRadius: 12,
              height: double.infinity,
            ),
          ),
          const SizedBox(height: 10),
          // Title skeleton
          const SkeletonLoader.text(width: double.infinity),
          const SizedBox(height: 6),
          // Subtitle skeleton
          const SkeletonLoader.text(width: 80, height: 10),
          const SizedBox(height: 8),
          // Price skeleton
          const SkeletonLoader.text(width: 60, height: 16),
        ],
      ),
    );
  }
}

/// Skeleton grid for POS products
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// Skeleton for stats cards on dashboard
class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader.circle(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader.text(width: 80),
                    SizedBox(height: 8),
                    SkeletonLoader.text(width: 120, height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for dashboard stats grid
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats cards skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: List.generate(4, (_) => const StatsCardSkeleton()),
          ),
          const SizedBox(height: 24),
          // Chart skeleton
          const SkeletonLoader.card(height: 200),
          const SizedBox(height: 24),
          // Recent orders skeleton
          const SkeletonLoader.card(height: 150),
        ],
      ),
    );
  }
}

/// Skeleton for list items
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          SkeletonLoader.circle(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader.text(width: 150),
                SizedBox(height: 8),
                SkeletonLoader.text(width: 100, height: 12),
              ],
            ),
          ),
          const SkeletonLoader.text(width: 60, height: 16),
        ],
      ),
    );
  }
}

/// Skeleton for a list of items
class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ListItemSkeleton(),
    );
  }
}
