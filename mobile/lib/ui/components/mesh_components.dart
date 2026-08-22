import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mesh_theme.dart';
import '../theme/mesh_tokens.dart';

class MeshPage extends StatelessWidget {
  const MeshPage({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.scrollable = true,
    this.maxWidth = 620,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MeshSpace.screen,
      vertical: MeshSpace.md,
    ),
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool scrollable;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      top: title == null,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: scrollable
              ? ListView(padding: padding, children: [child])
              : Padding(padding: padding, child: child),
        ),
      ),
    );
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: body,
    );
  }
}

/// A large-title collapsing-header variant of [MeshPage]. Use for tab roots
/// (Home, Rooms, Activity, You) where an editorial, magazine-style header
/// reads better than a compact centered [AppBar] title. Deep/detail pages
/// within a tab should keep using [MeshPage].
class MeshScaffold extends StatelessWidget {
  const MeshScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MeshSpace.screen,
                    MeshSpace.md,
                    MeshSpace.screen,
                    MeshSpace.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: textTheme.displaySmall),
                              if (subtitle != null) ...[
                                const SizedBox(height: MeshSpace.xs),
                                Text(
                                  subtitle!,
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ),
                for (final sliver in slivers) sliver,
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: MeshSpace.xl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MeshSectionTitle extends StatelessWidget {
  const MeshSectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MeshSpace.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: MeshSpace.xs),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

/// A small uppercase caption used above section titles, on status chips, or
/// to label a data field (e.g. "SITE ID", "LAST SEEN"). Distinct from
/// [MeshSectionTitle], which is the section heading itself.
class MeshMicroLabel extends StatelessWidget {
  const MeshMicroLabel(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color ?? palette.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }
}

class MeshCard extends StatelessWidget {
  const MeshCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MeshSpace.md),
    this.tint,
    this.onTap,
    this.matte = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? tint;
  final VoidCallback? onTap;
  final bool matte;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      decoration: BoxDecoration(
        color: tint ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(MeshRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        // Dark mode: a faint 1px top highlight reads better on a near-black
        // canvas than a drop shadow, which turns murky. Light mode keeps the
        // soft resting shadow since it has room for it.
        boxShadow: dark || matte ? null : MeshShadows.resting,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(MeshRadius.md),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

enum MeshStatusTone { neutral, active, critical }

class MeshStatusPill extends StatelessWidget {
  const MeshStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = MeshStatusTone.neutral,
  });

  final String label;
  final IconData? icon;
  final MeshStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final (foreground, background) = switch (tone) {
      MeshStatusTone.active => (palette.live, palette.live.withValues(alpha: 0.14)),
      MeshStatusTone.critical => (palette.ember, palette.ember.withValues(alpha: 0.14)),
      MeshStatusTone.neutral => (
        Theme.of(context).colorScheme.onSurfaceVariant,
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: MeshSpace.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(MeshRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.circle,
              size: icon == null ? 7 : 15,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal strip of compact stats (mesh status, peer count, last-seen,
/// zone) rendered with tabular figures so values don't jitter as they
/// update live. Intended for the Home hero and Activity headers.
class MeshStatRailItem {
  const MeshStatRailItem({
    required this.label,
    required this.value,
    this.icon,
    this.tone = MeshStatusTone.neutral,
  });

  final String label;
  final String value;
  final IconData? icon;
  final MeshStatusTone tone;
}

class MeshStatRail extends StatelessWidget {
  const MeshStatRail({super.key, required this.items});

  final List<MeshStatRailItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final numeric = Theme.of(context).extension<MeshNumericStyle>()?.style;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: MeshSpace.sm),
            _MeshStatRailCell(item: items[i], palette: palette, numeric: numeric),
          ],
        ],
      ),
    );
  }
}

class _MeshStatRailCell extends StatelessWidget {
  const _MeshStatRailCell({
    required this.item,
    required this.palette,
    required this.numeric,
  });

  final MeshStatRailItem item;
  final MeshPalette palette;
  final TextStyle? numeric;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (item.tone) {
      MeshStatusTone.active => palette.live,
      MeshStatusTone.critical => palette.ember,
      MeshStatusTone.neutral => palette.mesh,
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(
        horizontal: MeshSpace.md,
        vertical: MeshSpace.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(MeshRadius.md),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 14, color: foreground),
                const SizedBox(width: 4),
              ],
              MeshMicroLabel(item.label),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: numeric?.copyWith(color: palette.text, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// A tabular-figure key/value row for telemetry: RSSI, hop counts, object
/// IDs, GPS coordinates, timestamps. Keeps numeric columns aligned as values
/// change, and gives every incident/mesh-debug screen one consistent look.
class MeshDataRow extends StatelessWidget {
  const MeshDataRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final numeric = Theme.of(context).extension<MeshNumericStyle>()?.style;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: palette.textMuted),
            const SizedBox(width: MeshSpace.sm),
          ],
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: MeshSpace.sm),
          Text(
            value,
            textAlign: TextAlign.right,
            style: numeric?.copyWith(
              color: emphasize ? palette.primary : palette.text,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-bleed hero surface with a faint signal-lattice field behind its
/// content — radial dashes at low alpha, echoing the SOS button's own
/// transmission motif. Used for the Home hero and other "this is the most
/// important screen" moments. Renders inert (static) when the platform
/// requests reduced motion.
class MeshHeroSurface extends StatefulWidget {
  const MeshHeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MeshSpace.screen,
      vertical: MeshSpace.lg,
    ),
    this.live = false,
  });

  final Widget child;
  final EdgeInsets padding;

  /// When true, the lattice shifts to the ember accent to signal an active
  /// SOS. Ember must stay reserved for this state — see palette rationale
  /// in mesh_tokens.dart.
  final bool live;

  @override
  State<MeshHeroSurface> createState() => _MeshHeroSurfaceState();
}

class _MeshHeroSurfaceState extends State<MeshHeroSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (_reduceMotion) {
        _drift.stop();
      } else {
        _drift.repeat();
      }
    } else if (!_drift.isAnimating && !_reduceMotion) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final accent = widget.live ? palette.ember : palette.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.canvas,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.06), palette.canvas),
            palette.canvas,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) => CustomPaint(
                painter: _SignalLatticePainter(
                  phase: _reduceMotion ? 0.0 : _drift.value,
                  color: accent,
                ),
              ),
            ),
          ),
          Padding(padding: widget.padding, child: widget.child),
        ],
      ),
    );
  }
}

class _SignalLatticePainter extends CustomPainter {
  const _SignalLatticePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // A sparse grid of short radial ticks, each breathing in alpha on a
    // slightly different phase offset — reads as ambient signal noise
    // rather than a literal grid.
    const spacing = 46.0;
    final paint = Paint()..strokeCap = StrokeCap.round;
    var row = 0;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      var col = 0;
      for (var x = spacing / 2; x < size.width; x += spacing) {
        final seed = (row * 7 + col * 13) % 100 / 100;
        final local = (phase + seed) % 1.0;
        final alpha = (0.05 * (0.5 + 0.5 * math.sin(local * math.pi * 2)))
            .clamp(0.0, 0.08);
        if (alpha > 0.005) {
          paint.color = color.withValues(alpha: alpha);
          paint.strokeWidth = 1.4;
          canvas.drawLine(
            Offset(x - 5, y),
            Offset(x + 5, y),
            paint,
          );
        }
        col++;
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(_SignalLatticePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}

class MeshActionTile extends StatelessWidget {
  const MeshActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final iconColor = selected
        ? palette.primary
        : Theme.of(context).colorScheme.onSurface;
    final content = compact
        ? Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: MeshSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          )
        : Column(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(height: MeshSpace.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: MeshSpace.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
    return MeshCard(
      onTap: onTap,
      tint: selected ? palette.primary.withValues(alpha: 0.08) : null,
      padding: compact
          ? const EdgeInsets.symmetric(
              horizontal: MeshSpace.md,
              vertical: MeshSpace.sm,
            )
          : const EdgeInsets.symmetric(
              horizontal: MeshSpace.sm,
              vertical: MeshSpace.md,
            ),
      child: content,
    );
  }
}

class MeshFullWidthButton extends StatelessWidget {
  const MeshFullWidthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.busy = false,
    this.matte = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool busy;
  final bool matte;

  @override
  Widget build(BuildContext context) {
    final content = busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: MeshSpace.sm),
              ],
              Flexible(child: Text(label)),
            ],
          );
    final style = matte
        ? const ButtonStyle(
            elevation: WidgetStatePropertyAll(0),
            shadowColor: WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          )
        : null;
    return SizedBox(
      width: double.infinity,
      child: secondary
          ? OutlinedButton(
              onPressed: busy ? null : onPressed,
              style: style,
              child: content,
            )
          : FilledButton(
              onPressed: busy ? null : onPressed,
              style: style,
              child: content,
            ),
    );
  }
}

class MeshEmptyState extends StatelessWidget {
  const MeshEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MeshSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: MeshSpace.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MeshSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: MeshSpace.md),
            action!,
          ],
        ],
      ),
    ),
  );
}

class MeshEmergencyStep extends StatelessWidget {
  const MeshEmergencyStep({
    super.key,
    required this.title,
    required this.detail,
    required this.complete,
  });

  final String title;
  final String detail;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MeshSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: complete ? palette.live : palette.textMuted,
            size: 22,
          ),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MeshSosButton extends StatefulWidget {
  const MeshSosButton({
    super.key,
    required this.onActivated,
    this.enabled = true,
    this.holdDuration = MeshMotion.hold,
  });

  final VoidCallback onActivated;
  final bool enabled;
  final Duration holdDuration;

  @override
  State<MeshSosButton> createState() => _MeshSosButtonState();
}

class _MeshSosButtonState extends State<MeshSosButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _hold;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
    _hold = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          HapticFeedback.heavyImpact();
          setState(() => _pressing = false);
          widget.onActivated();
          _hold.reset();
        }
      });
  }

  void _start() {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    setState(() => _pressing = true);
    _hold.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant MeshSosButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdDuration != widget.holdDuration) {
      _hold.duration = widget.holdDuration;
    }
  }

  void _cancel() {
    if (!_pressing) return;
    setState(() => _pressing = false);
    _hold.animateBack(0, duration: MeshMotion.quick);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final palette = MeshPalette.of(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label:
          'SOS emergency. Press and hold for ${widget.holdDuration.inSeconds} seconds.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _hold]),
          builder: (context, _) {
            final pulse = reduceMotion ? 0.0 : _pulse.value;
            final scale = _pressing ? 0.97 : 1.0;
            // Idle state uses the deep oxblood; once the hold begins, the
            // button warms toward ember — the one place in the app where
            // that brighter red is allowed to appear.
            final coreColor = Color.lerp(
              palette.primary,
              palette.ember,
              _hold.value,
            )!;
            return Transform.scale(
              scale: scale,
              child: SizedBox.square(
                dimension: 240,
                child: CustomPaint(
                  painter: _SosPulsePainter(pulse: pulse, color: palette.ember),
                  child: Center(
                    child: CustomPaint(
                      painter: _SosProgressPainter(
                        progress: _hold.value,
                        color: palette.ember,
                      ),
                      child: Container(
                        width: 152,
                        height: 152,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [coreColor, palette.primary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: coreColor.withValues(alpha: 0.45),
                              blurRadius: 34,
                              spreadRadius: 7,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _pressing
                                    ? '${math.max(1, (widget.holdDuration.inSeconds - _hold.value * widget.holdDuration.inSeconds).ceil())}'
                                    : 'SOS',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(color: palette.onPrimary),
                              ),
                              Text(
                                _pressing ? 'KEEP HOLDING' : 'EMERGENCY',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: palette.onPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SosPulsePainter extends CustomPainter {
  const _SosPulsePainter({required this.pulse, required this.color});

  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Draw outward-moving signal dashes instead of rings. Rings can visually
    // appear to snap back to the button when the loop restarts; short radial
    // dashes read as transmissions traveling away from the SOS source.
    for (var layer = 0; layer < 3; layer++) {
      final phase = (pulse + layer / 3) % 1;
      final emerge = (phase / 0.14).clamp(0.0, 1.0).toDouble();
      final fade = ((1 - phase) / 0.3).clamp(0.0, 1.0).toDouble();
      final alpha = 0.42 * emerge * fade;
      if (alpha <= 0.01) continue;

      final radius = 78 + 36 * phase;
      final dashLength = 9 + 8 * phase;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5 - layer * 0.6
        ..strokeCap = StrokeCap.round;

      for (var index = 0; index < 20; index++) {
        final angle = (math.pi * 2 * index / 20) + layer * 0.06;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final start = center + direction * radius;
        final end = center + direction * (radius + dashLength);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SosPulsePainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.color != color;
}

class _SosProgressPainter extends CustomPainter {
  const _SosProgressPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SosProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
