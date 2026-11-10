import 'package:flutter/material.dart';

class NexLoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const NexLoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  const NexLoadingSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = size / 2;

  const NexLoadingSkeleton.card({super.key})
    : width = null,
      height = 120,
      borderRadius = 12;

  const NexLoadingSkeleton.text({super.key, this.width})
    : height = 14,
      borderRadius = 4;

  @override
  State<NexLoadingSkeleton> createState() => _NexLoadingSkeletonState();
}

class _NexLoadingSkeletonState extends State<NexLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _animation.value, 0),
              end: Alignment(1.0 + 2.0 * _animation.value, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

class NexCardSkeleton extends StatelessWidget {
  final int lines;

  const NexCardSkeleton({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const NexLoadingSkeleton.circle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NexLoadingSkeleton.text(
                        width: MediaQuery.sizeOf(context).width * 0.4,
                      ),
                      const SizedBox(height: 8),
                      const NexLoadingSkeleton.text(width: 80),
                    ],
                  ),
                ),
              ],
            ),
            for (var i = 0; i < lines; i++) ...[
              const SizedBox(height: 12),
              NexLoadingSkeleton.text(width: i == lines - 1 ? 160 : null),
            ],
          ],
        ),
      ),
    );
  }
}

class NexListSkeleton extends StatelessWidget {
  final int itemCount;

  const NexListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: NexCardSkeleton(lines: 2),
        ),
      ),
    );
  }
}
