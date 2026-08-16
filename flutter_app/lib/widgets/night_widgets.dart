import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class NightScaffold extends StatelessWidget {
  const NightScaffold({
    required this.child,
    this.title,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.showBrandInHeader = true,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final bool showBrandInHeader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF3B0022), NightColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: title == null
                    ? child
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IgHeader(
                            title: title!,
                            actions: actions,
                            showBrand: showBrandInHeader,
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: child),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IgHeader extends StatelessWidget {
  const IgHeader({
    required this.title,
    this.actions,
    this.showBrand = true,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (showBrand)
            const NeonWordmark(fontSize: 28)
          else
            const SizedBox(width: 28),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          if (actions == null || actions!.isEmpty)
            const SizedBox(width: 28)
          else
            Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ],
      ),
    );
  }
}

class NightCard extends StatelessWidget {
  const NightCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: NightColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: NightColors.accent.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: neonGlow(NightColors.accent.withValues(alpha: 0.55)),
      ),
      child: child,
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({this.centered = true, super.key});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        const NeonWordmark(fontSize: 52),
        const SizedBox(height: 10),
        Text(
          'Every good night deserves a recap.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(color: NightColors.muted),
        ),
      ],
    );
  }
}

class NeonWordmark extends StatelessWidget {
  const NeonWordmark({this.fontSize = 36, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Night',
            style: TextStyle(
              fontFamily: 'Yellowtail',
              fontSize: fontSize,
              height: 1,
              color: NightColors.accent,
              shadows: neonShadows(NightColors.accent),
            ),
          ),
          TextSpan(
            text: 'Capt',
            style: TextStyle(
              fontFamily: 'Yellowtail',
              fontSize: fontSize,
              height: 1,
              color: NightColors.orange,
              shadows: neonShadows(NightColors.orange),
            ),
          ),
        ],
      ),
      semanticsLabel: 'NightCapt',
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null ? null : neonGlow(),
      ),
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class AuthMethodTabs extends StatelessWidget {
  const AuthMethodTabs({
    required this.usePhone,
    required this.onChanged,
    super.key,
  });

  final bool usePhone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab('UK phone', usePhone, () => onChanged(true)),
        const SizedBox(width: 18),
        _tab('Email', !usePhone, () => onChanged(false)),
      ],
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? NightColors.accent : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: selected
              ? neonGlow(NightColors.accent.withValues(alpha: 0.7))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : NightColors.muted,
          ),
        ),
      ),
    );
  }
}

class NightTextField extends StatelessWidget {
  const NightTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      decoration: nightInputDecoration(label),
    );
  }
}

class StatusText extends StatelessWidget {
  const StatusText(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message, style: const TextStyle(color: NightColors.mint)),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NightCard(
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return NightCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: NightColors.accent,
            shadows: neonShadows(NightColors.accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: NightColors.muted),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.avatarUrl,
    this.radius = 22,
    this.glow = true,
    super.key,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [NightColors.accent, NightColors.orange],
        ),
        boxShadow: glow
            ? neonGlow(NightColors.accent.withValues(alpha: 0.5))
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: NightColors.accent,
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
        child: avatarUrl == null
            ? Text(
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
              )
            : null,
      ),
    );
  }
}

class PhotoButton extends StatelessWidget {
  const PhotoButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedNeonPainter(),
        child: Container(
          height: 118,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: NightColors.accent, size: 28),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NightColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              if (filled)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Added',
                    style: TextStyle(color: NightColors.mint, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedNeonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NightColors.accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarRating extends StatelessWidget {
  const StarRating({required this.value, required this.onChanged, super.key});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        final selected = (value ?? 0) >= star;
        return IconButton(
          onPressed: () => onChanged(star),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            size: 36,
            color: NightColors.orange,
            shadows: neonShadows(NightColors.orange),
          ),
        );
      }),
    );
  }
}

class InstagramNavBar extends StatelessWidget {
  const InstagramNavBar({
    required this.index,
    required this.onChanged,
    super.key,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home, 'Feed'),
      (Icons.people_outline, Icons.people, 'Friends'),
      (Icons.add, Icons.add, 'Create'),
      (Icons.favorite_border, Icons.favorite, 'Memories'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: index == i ? items[i].$2 : items[i].$1,
                    label: items[i].$3,
                    selected: index == i,
                    isCreate: i == 2,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isCreate,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isCreate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NightColors.accent : Colors.white;
    final iconWidget = Icon(
      icon,
      color: color,
      size: 26,
      shadows: selected ? neonShadows(NightColors.accent) : null,
    );
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCreate)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1.6),
                boxShadow: selected ? neonGlow() : null,
              ),
              child: Icon(icon, size: 18, color: color),
            )
          else
            iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: selected ? NightColors.accent : NightColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
