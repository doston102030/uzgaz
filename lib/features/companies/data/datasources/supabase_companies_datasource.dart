import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/company.dart';

/// Reads the buyer-facing company list from the `companies` table (see
/// `supabase/catalog_setup.sql`). Every seller has a row there
/// (`supabase/marketplace_setup.sql`); `is_available` is true only while
/// the admin has the seller approved.
Future<List<Company>> fetchCompanies() async {
  final rows = await SupabaseService.client
      .from('companies')
      .select()
      .eq('is_available', true)
      // Retired demo IDs; also excluded while the database cleanup is pending.
      .not('id', 'in', '(c1,c2,c3,c4,c5,c6)')
      .order('rating', ascending: false);

  return rows.map(_companyFromRow).toList();
}

Company _companyFromRow(Map<String, dynamic> row) {
  return Company(
    id: row['id'] as String,
    name: row['name'] as String,
    logoUrl: (row['logo_url'] as String?) ?? '',
    rating: (row['rating'] as num).toDouble(),
    reviewCount: row['review_count'] as int,
    distanceKm: (row['distance_km'] as num).toDouble(),
    productPrice: row['product_price'] as int,
    deliveryFee: row['delivery_fee'] as int,
    etaMinutes: row['eta_minutes'] as int,
    workingHours: row['working_hours'] as String,
    isAvailable: row['is_available'] as bool,
    latitude: (row['latitude'] as num).toDouble(),
    longitude: (row['longitude'] as num).toDouble(),
    address: (row['address'] as String?) ?? '',
    phone: (row['phone'] as String?) ?? '',
    tags: (row['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
  );
}
