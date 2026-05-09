import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Un contador que anima el valor numérico de forma fluida.
class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        final formatted = val.toStringAsFixed(value is int ? 0 : 2);
        return Text('$prefix$formatted$suffix', style: style);
      },
    );
  }
}

/// Control segmentado premium con indicador animado.
class PremiumSegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final Function(int) onSelected;

  const PremiumSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 8) / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutBack,
                left: selectedIndex * itemWidth,
                width: itemWidth,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                ),
              ),
              Row(
                children: List.generate(options.length, (i) => Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(i),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: selectedIndex == i ? AppTheme.primary : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                          fontWeight: selectedIndex == i ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 13,
                        ),
                        child: Text(options[i]),
                      ),
                    ),
                  ),
                )),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Botón de acción flotante expandible.
class ExpandableFab extends StatefulWidget {
  final List<ExpandableFabItem> items;
  final IconData icon;

  const ExpandableFab({super.key, required this.items, this.icon = Icons.add_rounded});

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ..._buildExpandingActionButtons(),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _toggle,
          heroTag: null,
          elevation: 8,
          backgroundColor: AppTheme.primary,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(_isOpen ? Icons.add_rounded : widget.icon, size: 28),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.items.length;
    final step = 1.0 / count;
    for (var i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          directionDegrees: 90,
          maxDistance: (count - i) * 60.0,
          progress: _expandAnimation,
          child: widget.items[i],
        ),
      );
    }
    return children;
  }
}

class ExpandableFabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ExpandableFabItem({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.softShadow,
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: theme.textTheme.bodyLarge?.color)),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onTap,
          elevation: 4,
          backgroundColor: theme.cardColor,
          foregroundColor: AppTheme.primary,
          child: Icon(icon),
        ),
      ],
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return FadeTransition(
          opacity: progress,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Tarjeta de métrica con mini-gráfico de tendencia.
class SparklineCard extends StatelessWidget {
  final String title;
  final num value;
  final List<double> data;
  final String prefix;
  final Color color;

  const SparklineCard({
    super.key,
    required this.title,
    required this.value,
    required this.data,
    this.prefix = '',
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.radiusMedium,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: value,
            prefix: prefix,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: theme.textTheme.titleLarge?.color),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: RepaintBoundary(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: data.reduce((a, b) => a < b ? a : b) * 0.9,
                  maxY: data.reduce((a, b) => a > b ? a : b) * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cargador universal con efecto Shimmer.
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
      highlightColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget list({int count = 5}) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const SkeletonLoader(width: 50, height: 50, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 150, height: 16),
                  const SizedBox(height: 8),
                  SkeletonLoader(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}

/// Estado vacío premium con diseño moderno.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
