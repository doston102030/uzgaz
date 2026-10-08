import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../constants/app_constants.dart';
import 'app_tappable.dart';
import 'category_artwork.dart';

/// Visible arrows make the full category list accessible on narrow screens.
class CategoryFilterBar extends StatefulWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final ServiceCategory? selected;
  final Map<ServiceCategory, int> counts;
  final ValueChanged<ServiceCategory?> onSelected;

  static double heightFor(BuildContext context) =>
      80 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 2.5;

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  final _scroll = ScrollController();
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelection();
  }

  @override
  void didUpdateWidget(CategoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _revealSelection();
  }

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selectedKey.currentContext;
      if (!mounted || target == null) return;
      // Only move this horizontal strip, never the parent page.
      final render = target.findRenderObject();
      if (render != null && _scroll.hasClients) {
        _scroll.position.ensureVisible(render, alignment: .5);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(double direction) {
    if (!_scroll.hasClients) return;
    final target =
        (_scroll.offset + direction * _scroll.position.viewportDimension * .8)
            .clamp(0.0, _scroll.position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return SizedBox(
      height: CategoryFilterBar.heightFor(context),
      child: Row(children: [
        IconButton(
          tooltip: 'Oldingi toifalar',
          onPressed: () => _move(-1),
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          constraints: const BoxConstraints.tightFor(width: 32, height: 48),
          padding: EdgeInsets.zero,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              for (final category in <ServiceCategory?>[
                null,
                ...ServiceCategory.values
              ])
                Padding(
                  key: category == widget.selected ? _selectedKey : null,
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    selected: category == widget.selected,
                    child: AppTappable(
                      onTap: () => widget.onSelected(category),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        width: (category == null ? 110 : 144) * scale,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: category == widget.selected
                              ? Color.alphaBlend(
                                  c.primary.withValues(alpha: .10), c.surface)
                              : c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: category == widget.selected
                                  ? c.primary
                                  : c.border,
                              width: category == widget.selected ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          if (category == null)
                            Icon(Icons.grid_view_rounded,
                                size: 24, color: c.primary)
                          else
                            CategoryArtwork(category: category, size: 36),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category?.titleUz ?? 'Barchasi',
                                    maxLines: 2,
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.25,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary)),
                                if (category != null &&
                                    (widget.counts[category] ?? 0) > 0)
                                  Text('${widget.counts[category]} ta',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: c.textSecondary)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        IconButton(
          tooltip: 'Keyingi toifalar',
          onPressed: () => _move(1),
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          constraints: const BoxConstraints.tightFor(width: 32, height: 48),
          padding: EdgeInsets.zero,
        ),
      ]),
    );
  }
}
