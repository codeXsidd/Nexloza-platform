import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/nex_stat_card.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../../automations/presentation/providers/automation_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final automationsAsync = ref.watch(automationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectsProvider);
          ref.invalidate(devicesProvider);
          ref.invalidate(automationsProvider);
        },
        child: ListView(
          padding: AppBreakpoints.screenPadding(context),
          children: [
            Text('Overview', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            ResponsiveGrid(
              children: [
                NexStatCard(
                  label: 'Projects',
                  value: projectsAsync.when(
                    data: (p) => '${p.length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.folder,
                  iconColor: AppColors.primary,
                ),
                NexStatCard(
                  label: 'Devices',
                  value: devicesAsync.when(
                    data: (d) => '${d.length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.devices_other,
                  iconColor: AppColors.secondary,
                ),
                NexStatCard(
                  label: 'Online',
                  value: devicesAsync.when(
                    data: (d) => '${d.where((x) => x.isOnline).length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.wifi,
                  iconColor: AppColors.success,
                ),
                NexStatCard(
                  label: 'Automations',
                  value: automationsAsync.when(
                    data: (a) => '${a.length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.auto_awesome,
                  iconColor: AppColors.warning,
                ),
              ],
            ),
            AppSpacing.verticalLg,
            Text('Device Status', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            SizedBox(
              height: 200,
              child: devicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('No data')),
                data: (devices) {
                  if (devices.isEmpty) {
                    return Center(
                      child: Text(
                        'No devices registered yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  final online = devices.where((d) => d.isOnline).length;
                  final offline = devices.length - online;
                  return _PieChart(
                    segments: [
                      _PieSegment(
                        'Online',
                        online.toDouble(),
                        AppColors.success,
                      ),
                      _PieSegment(
                        'Offline',
                        offline.toDouble(),
                        AppColors.error,
                      ),
                    ],
                  );
                },
              ),
            ),
            AppSpacing.verticalLg,
            Text('Projects by Category', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            projectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load'),
              data: (projects) {
                if (projects.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Text(
                        'No projects yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                final categories = <String, int>{};
                for (final p in projects) {
                  final cat = p.category ?? 'Custom';
                  categories[cat] = (categories[cat] ?? 0) + 1;
                }
                final sorted = categories.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      children: sorted.map((e) {
                        final pct = e.value / projects.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  e.key,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 12,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                ),
                              ),
                              AppSpacing.horizontalSm,
                              Text(
                                '${e.value}',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            AppSpacing.verticalLg,
            Text('Automation Health', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            automationsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load'),
              data: (automations) {
                if (automations.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Text(
                        'No automations configured',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                final enabled = automations.where((a) => a.isEnabled).length;
                final disabled = automations.length - enabled;
                return Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Total',
                            value: '${automations.length}',
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Enabled',
                            value: '$enabled',
                            color: AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Disabled',
                            value: '$disabled',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            AppSpacing.verticalXl,
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PieSegment {
  final String label;
  final double value;
  final Color color;

  const _PieSegment(this.label, this.value, this.color);
}

class _PieChart extends StatelessWidget {
  final List<_PieSegment> segments;

  const _PieChart({required this.segments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(160, 160),
            painter: _PieChartPainter(
              segments: segments,
              holeColor: theme.scaffoldBackgroundColor,
            ),
          ),
        ),
        AppSpacing.horizontalMd,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: segments.map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.label}: ${s.value.toInt()}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final Color holeColor;

  _PieChartPainter({required this.segments, required this.holeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    final holePaint = Paint()
      ..color = holeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      segments != old.segments || holeColor != old.holeColor;
}
