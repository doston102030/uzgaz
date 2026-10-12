import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/promo_banner.dart';

/// The banners the admin has switched on, in their order
/// (supabase/promo_banners_setup.sql).
Future<List<PromoBanner>> fetchPromoBanners() async {
  final rows = await SupabaseService.client
      .from('promo_banners')
      .select()
      .eq('is_active', true)
      .order('sort_order')
      .order('created_at')
      .order('id')
      .timeout(const Duration(seconds: 10));
  return rows
      .map(PromoBanner.fromRow)
      .where((banner) => banner.title.isNotEmpty)
      .toList();
}
