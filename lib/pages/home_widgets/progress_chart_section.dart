import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../config/home_design_tokens.dart';
import '../../models/course_model.dart';

class ProgressChartSection extends StatefulWidget {
  const ProgressChartSection({super.key, required this.courses});

  final List<CourseModel> courses;

  @override
  State<ProgressChartSection> createState() => _ProgressChartSectionState();
}

class _ProgressChartSectionState extends State<ProgressChartSection> {
  bool _animateBars = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateBars = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chartItems = _buildChartItems();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeSpacing.s16),
      child: Container(
        padding: const EdgeInsets.all(HomeSpacing.s16),
        decoration: BoxDecoration(
          color: HomeColors.surface1,
          borderRadius: BorderRadius.circular(HomeRadius.r24),
          border: Border.all(
            color: HomeColors.stroke,
            width: HomeEffects.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: HomeColors.shadow,
              blurRadius: HomeEffects.softElevation,
              offset: HomeEffects.shadowOffset,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: HomeTypography.title),
            const Gap(HomeSpacing.s4),
            Text(
              'Learning pace across active courses',
              style: HomeTypography.caption,
            ),
            const Gap(HomeSpacing.s16),
            SizedBox(
              height: 138,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= chartItems.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: HomeSpacing.s8),
                            child: Text(
                              chartItems[idx].label,
                              style: HomeTypography.caption,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(chartItems.length, (index) {
                    final item = chartItems[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _animateBars ? item.value : 0,
                          width: 18,
                          borderRadius: BorderRadius.circular(HomeRadius.r12),
                          color: index == 1
                              ? AppColors.accent
                              : AppColors.primary,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: AppColors.grey100,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                swapAnimationDuration: const Duration(milliseconds: 700),
                swapAnimationCurve: Curves.easeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ChartItem> _buildChartItems() {
    if (widget.courses.isEmpty) {
      return const [
        _ChartItem(label: 'Su', value: 30),
        _ChartItem(label: 'Wi', value: 55),
        _ChartItem(label: 'Sp', value: 40),
        _ChartItem(label: 'Ha', value: 48),
      ];
    }

    final selected = widget.courses.take(4).toList();
    final computed = selected
        .map(
          (course) =>
              (course.duration + (course.modules.length * 3)).toDouble(),
        )
        .toList();

    final maxRaw = computed.reduce((a, b) => a > b ? a : b);

    return List.generate(selected.length, (index) {
      final course = selected[index];
      final value = maxRaw <= 0 ? 0 : (computed[index] / maxRaw) * 100;
      final label = course.title.trim().isEmpty
          ? 'C${index + 1}'
          : course.title.trim().substring(
              0,
              course.title.trim().length >= 2 ? 2 : 1,
            );

      return _ChartItem(
        label: label,
        value: value.clamp(16.0, 100.0).toDouble(),
      );
    });
  }
}

class _ChartItem {
  const _ChartItem({required this.label, required this.value});

  final String label;
  final double value;
}
