import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';

class FanLogo extends StatelessWidget {
  const FanLogo({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    ShaderMask(
      shaderCallback: (bounds) => FanColors.gradient.createShader(bounds),
      child: Text('FAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: size,
        letterSpacing: -2.7, color: Colors.white, height: 1.0)),
    ),
    Padding(padding: const EdgeInsets.only(left: 2), child: Icon(Icons.auto_awesome,
      color: FanColors.pink, size: size * .48)),
  ]);
}

class FanButton extends StatelessWidget {
  const FanButton({super.key, required this.label, required this.onPressed,
    this.icon = Icons.arrow_forward_rounded, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52, width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(gradient: FanColors.gradient, borderRadius: BorderRadius.circular(17)),
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF24112E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
        child: loading ? const SizedBox(width: 21, height: 21,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF24112E)))
          : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 19)],
            ]),
      ),
    ),
  );
}

class FanSectionHeading extends StatelessWidget {
  const FanSectionHeading({super.key, required this.title, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 15),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
        letterSpacing: -.55))),
      if (trailing != null) TextButton(onPressed: onTap,
        child: Text(trailing!, style: const TextStyle(fontSize: 11, color: FanColors.orchid))),
    ]),
  );
}

class FanTag extends StatelessWidget {
  const FanTag(this.label, {super.key, this.selected = false, this.onTap, this.icon});
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20), onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected ? FanColors.orchid : FanColors.surface2,
        border: Border.all(color: selected ? Colors.transparent : FanColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: selected ? FanColors.background : FanColors.orchid), const SizedBox(width: 6)],
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
          color: selected ? FanColors.background : FanColors.ink)),
      ]),
    ),
  );
}

class FanCover extends StatelessWidget {
  const FanCover({super.key, required this.story, this.width = 145,
    this.height = 207, this.onTap, this.featured = false});
  final FanStory story;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height, child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Material(color: FanColors.surface2, child: InkWell(onTap: onTap, child: Stack(
      fit: StackFit.expand,
      children: [
        story.coverUrl.isNotEmpty
          ? Image.network(story.coverUrl, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(story.coverAsset, fit: BoxFit.cover))
          : Image.asset(story.coverAsset, fit: BoxFit.cover),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x22000000), Color(0xF5090712)],
          stops: [0, .42, 1],
        ))),
        Positioned(left: 12, top: 12, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xAD201332), borderRadius: BorderRadius.circular(10)),
          child: Text(story.category.toUpperCase(), style: const TextStyle(
            fontSize: 8, letterSpacing: .7, fontWeight: FontWeight.w800,
            color: FanColors.pink)),
        )),
        Positioned(left: 12, right: 10, bottom: featured ? 22 : 12, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Text(story.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: featured ? 23 : 14,
                fontWeight: FontWeight.w900, height: 1.18)),
            const SizedBox(height: 5),
            Text('por ${story.authorName}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: featured ? 11 : 9.5,
                color: FanColors.ink.withOpacity(.75))),
          ],
        )),
      ],
    ))),
  ));
}

class FanStoryRow extends StatelessWidget {
  const FanStoryRow({super.key, required this.story, required this.onTap, this.subtitle});
  final FanStory story;
  final VoidCallback onTap;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(16),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      FanCover(story: story, width: 72, height: 92, onTap: onTap),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(subtitle ?? '${story.category}  ·  ${story.episodeCount} episódios',
          style: const TextStyle(fontSize: 11, color: FanColors.muted)),
        const SizedBox(height: 7),
        Text(story.description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: FanColors.muted, height: 1.5)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: FanColors.muted),
    ])),
  );
}

void fanMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
