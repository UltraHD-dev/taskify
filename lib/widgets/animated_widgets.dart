import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final Duration delay;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(
          delay: delay,
          duration: const Duration(milliseconds: 300),
        ),
        SlideEffect(
          delay: delay,
          duration: const Duration(milliseconds: 300),
          begin: const Offset(0, 0.1),
          end: const Offset(0, 0),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const AnimatedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 300),
        ),
        ScaleEffect(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 300),
        ),
      ],
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(26),
              child: Center(
                child: Animate(
                  effects: const [
                    ScaleEffect(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ],
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Загрузка...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyStateAnimation extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateAnimation({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 300)),
          ScaleEffect(duration: Duration(milliseconds: 300)),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).shimmer(
              duration: const Duration(seconds: 2),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}