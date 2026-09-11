import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/product.dart';

/// Reads the buyer-facing catalogue from the `products` table (see
/// `supabase/catalog_setup.sql`). Replaces `mockProducts` — the UI still
/// only depends on [Product].
Future<List<Product>> fetchProducts() async {
  final rows = await SupabaseService.client
      .from('products')
      .select()
      .order('created_at');

  return rows.map(_productFromRow).toList();
}

Product _productFromRow(Map<String, dynamic> row) {
  return Product(
    id: row['id'] as String,
    name: row['name'] as String,
    imageUrl: (row['image_url'] as String?) ?? '',
    price: row['price'] as int,
    oldPrice: row['old_price'] as int?,
    rating: (row['rating'] as num).toDouble(),
    reviewCount: row['review_count'] as int,
    isAvailable: row['is_available'] as bool,
    isPopular: row['is_popular'] as bool,
    companyId: (row['company_id'] as String?) ?? '',
    companyName: row['company_name'] as String,
    categoryId: row['category_id'] as String,
    description: row['description'] as String?,
    unit: (row['unit'] as String?) ?? 'dona',
    specs: (row['specs'] as Map?)?.map((k, v) => MapEntry(k as String, v.toString())) ?? const {},
  );
}
