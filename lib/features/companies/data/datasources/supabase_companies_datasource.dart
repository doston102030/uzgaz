import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/company.dart';

/// Reads the buyer-facing company list from the `companies` table (see
/// `supabase/catalog_setup.sql`). Replaces `mockCompanies` — the UI still
/// only depends on [Company].
Future<List<Company>> fetchCompanies() async {
  final rows = await SupabaseService.client
      .from('companies')
      .select()
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
