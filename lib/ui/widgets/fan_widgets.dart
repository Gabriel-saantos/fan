import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';

class FanLogo extends StatelessWidget {
  const FanLogo({super.key, this.size = 30});
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size + 6,
        height: size + 6,
        decoration: BoxDecoration(
          gradient: FanColors.gradient,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: FanColors.background,
          size: size * .7,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'fan',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: size,
          letterSpacing: -1.5,
          color: FanColors.ink,
        ),
      ),
    ],
  );
}

class FanButton extends StatelessWidget {
  const FanButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: FanColors.purple,
        foregroundColor: FanColors.background,
        disabledBackgroundColor: FanColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, size: 20),
                ],
              ],
            ),
    ),
  );
}

class FanPageHeader extends StatelessWidget {
  const FanPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.action,
  });
  final String title, subtitle;
  final String? eyebrow;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: const TextStyle(
              color: FanColors.orchid,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: FanColors.muted, height: 1.6),
        ),
      ],
    ),
  );
}

class FanSectionHeading extends StatelessWidget {
  const FanSectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              trailing!,
              style: const TextStyle(color: FanColors.orchid),
            ),
          ),
      ],
    ),
  );
}

class FanTag extends StatelessWidget {
  const FanTag(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: onTap != null,
    child: Material(
      color: selected
          ? FanColors.purple.withValues(alpha: .18)
          : FanColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? FanColors.purple : FanColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: FanColors.orchid),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? FanColors.orchid : FanColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FanArtwork extends StatelessWidget {
  const FanArtwork({super.key, required this.story, this.fit = BoxFit.cover});
  final FanStory story;
  final BoxFit fit;
  Widget _fallback() => Image.asset(
    story.coverAsset,
    fit: fit,
    errorBuilder: (_, error, stack) => Container(
      color: FanColors.surface2,
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: FanColors.orchid,
          size: 40,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (story.coverUrl.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(story.coverUrl.split(',').last),
          fit: fit,
          errorBuilder: (_, error, stack) => _fallback(),
        );
      } catch (_) {
        return _fallback();
      }
    }
    if (story.coverUrl.isEmpty) return _fallback();
    return Image.network(
      story.coverUrl,
      fit: fit,
      errorBuilder: (_, error, stack) => _fallback(),
    );
  }
}

class FanCover extends StatelessWidget {
  const FanCover({
    super.key,
    required this.story,
    this.width = 160,
    this.height = 220,
    this.onTap,
    this.featured = false,
  });
  final FanStory story;
  final double width, height;
  final VoidCallback? onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${story.title}, ${story.category}',
    button: onTap != null,
    child: SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: FanColors.surface2,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FanArtwork(story: story),
                if (featured) ...[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xF5101017)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FanStoryCard extends StatelessWidget {
  const FanStoryCard({super.key, required this.story, required this.onTap});
  final FanStory story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Abrir ${story.title}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: .78,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FanArtwork(story: story),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: FanColors.background.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${story.category} · ${story.format == StoryFormat.chat ? 'Chat' : 'Livro'}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            story.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            story.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: FanColors.muted),
          ),
          const SizedBox(height: 7),
          Text(
            '${story.episodeCount} ${story.format.unit} · ${story.contentRating}',
            style: const TextStyle(fontSize: 11, color: FanColors.orchid),
          ),
        ],
      ),
    ),
  );
}

class FanStoryRow extends StatelessWidget {
  const FanStoryRow({
    super.key,
    required this.story,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });
  final FanStory story;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            FanCover(story: story, width: 64, height: 84),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle ??
                        '${story.format.label} · ${story.episodeCount} ${story.format.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: FanColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.authorName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FanColors.orchid,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: FanColors.muted,
                ),
          ],
        ),
      ),
    ),
  );
}

class FanEmptyState extends StatelessWidget {
  const FanEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    decoration: BoxDecoration(
      color: FanColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: FanColors.line),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: FanColors.purple.withValues(alpha: .12),
          child: Icon(icon, color: FanColors.orchid, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: FanColors.muted, height: 1.6),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

EdgeInsets fanPagePadding(BuildContext context) => EdgeInsets.fromLTRB(
  MediaQuery.sizeOf(context).width > 800 ? 36 : 20,
  30,
  MediaQuery.sizeOf(context).width > 800 ? 36 : 20,
  36,
);

void fanMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String fanError(Object error) {
  if (error is StateError) return error.message;
  return 'Não foi possível concluir. Verifique sua conexão e tente novamente.';
}
