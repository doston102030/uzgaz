import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/mock_products.dart';
import '../../domain/entities/product.dart';

final productsProvider = Provider<List<Product>>((ref) => mockProducts);

final productByIdProvider = Provider.family<Product?, String>((ref, id) {
  final products = ref.watch(productsProvider);
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
});

final productsByCategoryProvider = Provider.family<List<Product>, String>((ref, categoryId) {
  return ref.watch(productsProvider).where((p) => p.categoryId == categoryId).toList();
});

final popularProductsProvider = Provider<List<Product>>((ref) {
  final products = [...ref.watch(productsProvider)];
  products.sort((a, b) {
    if (a.isPopular != b.isPopular) return a.isPopular ? -1 : 1;
    return b.rating.compareTo(a.rating);
  });
  return products;
});

/// `null` = "Barchasi" — the catalogue's default tab.
final categoryFilterProvider = StateProvider<ServiceCategory?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

enum ProductSort { tavsiya, arzon, qimmat, reyting }

extension ProductSortX on ProductSort {
  String get label => switch (this) {
        ProductSort.tavsiya => 'Tavsiya etilgan',
        ProductSort.arzon => 'Avval arzoni',
        ProductSort.qimmat => 'Avval qimmati',
        ProductSort.reyting => 'Reyting bo‘yicha',
      };
}

final productSortProvider = StateProvider<ProductSort>((ref) => ProductSort.tavsiya);

/// Category + text search + sort, applied in that order.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final category = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(productSortProvider);

  var products = ref.watch(productsProvider).where((p) {
    final matchesCategory = category == null || p.categoryId == category.id;
    final matchesQuery = query.isEmpty ||
        p.name.toLowerCase().contains(query) ||
        p.companyName.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();

  switch (sort) {
    case ProductSort.arzon:
      products.sort((a, b) => a.price.compareTo(b.price));
    case ProductSort.qimmat:
      products.sort((a, b) => b.price.compareTo(a.price));
    case ProductSort.reyting:
      products.sort((a, b) => b.rating.compareTo(a.rating));
    case ProductSort.tavsiya:
      products.sort((a, b) {
        if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
        if (a.isPopular != b.isPopular) return a.isPopular ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });
  }
  return products;
});

/// Counts per category for the catalogue chips.
final categoryCountsProvider = Provider<Map<ServiceCategory, int>>((ref) {
  final products = ref.watch(productsProvider);
  return {
    for (final category in ServiceCategory.values)
      category: products.where((p) => p.categoryId == category.id).length,
  };
});
