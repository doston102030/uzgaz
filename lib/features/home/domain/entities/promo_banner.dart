import 'package:flutter/material.dart';

/// One home-page promo banner, as the admin panel's "Reklama" section
/// writes it to the `promo_banners` table (supabase/promo_banners_setup.sql).
class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    this.caption = '',
    required this.accent,
    this.imageUrl,
    this.icon = 'flame',
    this.link = '',
  });

  final String id;
  final String title;
  final String caption;
  final Color accent;

  /// A Storage URL, or `asset:assets/images/…` for a picture shipped with
  /// the app. Null: the [icon] badge is drawn instead.
  final String? imageUrl;

  /// flame | cylinder | bolt | truck | tag.
  final String icon;

  /// `category:<ServiceCategory name>`, `services`, `url:https://…` or ''.
  final String link;

  /// Only web links can be opened from an admin-authored banner.
  Uri? get externalUri {
    if (!link.startsWith('url:')) return null;
    final uri = Uri.tryParse(link.substring('url:'.length));
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  /// The bundled picture's asset path when [imageUrl] is `asset:…`.
  String? get assetPath => imageUrl != null && imageUrl!.startsWith('asset:')
      ? imageUrl!.substring('asset:'.length)
      : null;

  /// A downloadable picture's URL (anything that is not an asset).
  String? get networkUrl =>
      imageUrl == null || imageUrl!.isEmpty || assetPath != null
          ? null
          : imageUrl;

  factory PromoBanner.fromRow(Map<String, dynamic> row) => PromoBanner(
        id: row['id'] as String,
        title: (row['title'] as String? ?? '').trim(),
        caption: (row['caption'] as String? ?? '').trim(),
        accent: parseColor(row['accent'] as String?),
        imageUrl: (row['image_url'] as String?)?.trim(),
        icon: row['icon'] as String? ?? 'flame',
        link: (row['link'] as String? ?? '').trim(),
      );

  /// `#RRGGBB` → colour; anything else falls back to the brand blue.
  static Color parseColor(String? hex) {
    final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
    if (value == null || (hex ?? '').replaceFirst('#', '').length != 6) {
      return const Color(0xFF2563EB);
    }
    return Color(0xFF000000 | value);
  }

  /// What the home page shows until the table exists (or when it can't be
  /// reached) — the same three banners the SQL file seeds.
  static const defaults = [
    PromoBanner(
      id: 'suyultirilgan',
      title: 'Suyultirilgan gaz',
      caption: 'Subsidiya narxida, aholi uchun',
      accent: Color(0xFF16A34A),
      icon: 'flame',
      link: 'category:suyultirilganGaz',
    ),
    PromoBanner(
      id: 'yetkazish',
      title: 'Gaz ballon yetkazish',
      caption: '35 daqiqada eshigingizga',
      accent: Color(0xFF2563EB),
      imageUrl: 'asset:assets/images/promo_gas_cylinder.png',
      icon: 'cylinder',
      link: 'category:gazBallon',
    ),
    PromoBanner(
      id: 'elektr',
      title: 'Elektr quvvatlash',
      caption: 'Zaryadlash tarmog‘i kengaymoqda',
      accent: Color(0xFF8B5CF6),
      icon: 'bolt',
      link: 'services',
    ),
  ];
}
