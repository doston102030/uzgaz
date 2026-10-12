import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/supabase_promo_banners_datasource.dart';
import '../../domain/entities/promo_banner.dart';

/// Home-page banners from the admin panel. An empty list is the admin's
/// choice (every banner switched off) and hides the carousel; only when
/// the table can't be read — not created yet, offline, tests — does the
/// page fall back to its built-in three.
final promoBannersProvider = FutureProvider<List<PromoBanner>>((ref) async {
  if (!SupabaseService.isReady) return PromoBanner.defaults;
  try {
    return await fetchPromoBanners();
  } catch (_) {
    return PromoBanner.defaults;
  }
});
