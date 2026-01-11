import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_colors.dart';

class StatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final String? subtitle;
  final String? trend;
  final bool isTrendPositive;
  final VoidCallback? onTap;
  final bool compact;
  final int animationDelay;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.gradient,
    this.subtitle,
    this.trend,
    this.isTrendPositive = true,
    this.onTap,
    this.compact = false,
    this.animationDelay = 0,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? AppColors.primary;
    final isDark = context.isDarkMode;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setTranslationRaw(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.compact ? 16 : 20),
            child: Container(
              padding: EdgeInsets.all(widget.compact ? 12 : 16), // Reduced padding
              decoration: BoxDecoration(
                gradient: widget.gradient,
                color: widget.gradient == null 
                    ? (widget.backgroundColor ?? (isDark ? AppColors.darkCardBackground : AppColors.cardBackground)) 
                    : null,
                borderRadius: BorderRadius.circular(widget.compact ? 16 : 20),
                border: Border.all(
                  color: _isHovered 
                      ? color.withValues(alpha: 0.3)
                      : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered 
                        ? color.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkShadowColor : AppColors.shadowColorLight),
                    blurRadius: _isHovered ? 20 : 12,
                    offset: Offset(0, _isHovered ? 8 : 4),
                    spreadRadius: _isHovered ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRect(
                child: widget.compact 
                    ? _buildCompactLayout(context, color) 
                    : _buildFullLayout(context, color),
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.animationDelay))
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildCompactLayout(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildIconContainer(color, isCompact: true),
            const Spacer(),
            if (widget.trend != null) _buildTrendBadge(isCompact: true),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconContainer(color, isCompact: false),
            if (widget.trend != null) _buildTrendBadge(isCompact: false),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            delay: Duration(milliseconds: 2000 + widget.animationDelay),
            duration: 1500.ms,
            color: color.withValues(alpha: 0.15),
          ),
        const SizedBox(height: 6),
        Text(
          widget.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconContainer(Color color, {required bool isCompact}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: _isHovered ? 0.2 : 0.12),
            color.withValues(alpha: _isHovered ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Icon(
        widget.icon,
        color: color,
        size: isCompact ? 20 : 26,
      ),
    );
  }

  Widget _buildTrendBadge({required bool isCompact}) {
    final isPositive = widget.isTrendPositive;
    final trendColor = isPositive ? AppColors.success : AppColors.error;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trendColor.withValues(alpha: 0.15),
            trendColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: isCompact ? 12 : 14,
            color: trendColor,
          ),
          SizedBox(width: isCompact ? 3 : 4),
          Text(
            widget.trend!,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(
        delay: Duration(milliseconds: 3000 + widget.animationDelay),
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: 1000.ms,
      );
  }
}

// Premium Gradient Stats Card for key metrics
class GradientStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final String? trend;
  final bool isTrendPositive;
  final VoidCallback? onTap;
  final int animationDelay;

  const GradientStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.trend,
    this.isTrendPositive = true,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTrendPositive ? Icons.trending_up : Icons.trending_down,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: animationDelay))
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
      .then()
      .shimmer(delay: 1000.ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.1));
  }
}

/// Pastel Stats Card - Modern clean design with icon on right and 3D wave background
/// Matches the reference UI with soft pastel backgrounds
class PastelStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final int animationDelay;
  final bool compact;

  const PastelStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.subtitle,
    this.onTap,
    this.animationDelay = 0,
    this.compact = false,
  });

  @override
  State<PastelStatsCard> createState() => _PastelStatsCardState();
}

class _PastelStatsCardState extends State<PastelStatsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setTranslationRaw(0.0, _isHovered ? -3.0 : 0.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.iconColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                    blurRadius: _isHovered ? 10 : 4,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top pastel section (empty space)
                  Expanded(
                    flex: 3,
                    child: const SizedBox(),
                  ),
                  // Bottom content section
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 10 : 14,
                        vertical: widget.compact ? 6 : 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left side - Text content
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: widget.compact ? 10 : 11,
                                      color: context.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: widget.compact ? 2 : 4),
                                  Text(
                                    widget.value,
                                    style: TextStyle(
                                      fontSize: widget.compact ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: context.isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (widget.subtitle != null) ...[
                                    SizedBox(height: widget.compact ? 1 : 2),
                                    Text(
                                      widget.subtitle!,
                                      style: TextStyle(
                                        fontSize: widget.compact ? 9 : 10,
                                        color: widget.iconColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Right side - Icon
                          Container(
                            padding: EdgeInsets.all(widget.compact ? 6 : 8),
                            decoration: BoxDecoration(
                              color: widget.iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.iconColor,
                              size: widget.compact ? 18 : 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.animationDelay))
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
