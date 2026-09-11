import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/supabase_companies_datasource.dart';
import '../../domain/entities/company.dart';

/// Fetches the catalogue once per app session from Supabase
/// (`companies` table). `ref.watch` this directly to show a loading /
/// error state; everything else in the app reads [companiesProvider]
/// below, which just unwraps the resolved list.
final companiesFutureProvider = FutureProvider<List<Company>>((ref) {
  return fetchCompanies();
});

/// Synchronous view of the catalogue — empty until the Supabase fetch
/// resolves, then live. Every existing screen/provider watches this, so
/// switching the fetch itself from mock to Supabase needed no other
/// file to change.
final companiesProvider = Provider<List<Company>>((ref) {
  return ref.watch(companiesFutureProvider).valueOrNull ?? const [];
});

final companySortProvider = StateProvider<CompanySortOption>(
  (ref) => CompanySortOption.engYaqin,
);

final sortedCompaniesProvider = Provider<List<Company>>((ref) {
  final companies = [...ref.watch(companiesProvider)];
  final sort = ref.watch(companySortProvider);

  // Unavailable companies always sink to the bottom, whatever the sort.
  int byAvailability(Company a, Company b) {
    if (a.isAvailable == b.isAvailable) return 0;
    return a.isAvailable ? -1 : 1;
  }

  companies.sort((a, b) {
    final availability = byAvailability(a, b);
    if (availability != 0) return availability;
    return switch (sort) {
      CompanySortOption.masofa || CompanySortOption.engYaqin =>
        a.distanceKm.compareTo(b.distanceKm),
      CompanySortOption.reyting => b.rating.compareTo(a.rating),
      CompanySortOption.narx || CompanySortOption.engArzon =>
        a.totalPrice.compareTo(b.totalPrice),
    };
  });
  return companies;
});

/// The single best company per criterion — drives the "Eng arzon" /
/// "Eng yaqin" / "Top reyting" ribbons on the comparison cards.
class CompanyHighlights {
  const CompanyHighlights({this.cheapestId, this.nearestId, this.topRatedId});

  final String? cheapestId;
  final String? nearestId;
  final String? topRatedId;

  String? labelFor(String id) {
    if (id == cheapestId) return 'Eng arzon';
    if (id == nearestId) return 'Eng yaqin';
    if (id == topRatedId) return 'Top reyting';
    return null;
  }
}

final companyHighlightsProvider = Provider<CompanyHighlights>((ref) {
  final available =
      ref.watch(companiesProvider).where((c) => c.isAvailable).toList();
  if (available.isEmpty) return const CompanyHighlights();

  final cheapest = available.reduce((a, b) => a.totalPrice <= b.totalPrice ? a : b);
  final nearest = available.reduce((a, b) => a.distanceKm <= b.distanceKm ? a : b);
  final topRated = available.reduce((a, b) => a.rating >= b.rating ? a : b);

  return CompanyHighlights(
    cheapestId: cheapest.id,
    nearestId: nearest.id == cheapest.id ? null : nearest.id,
    topRatedId: (topRated.id == cheapest.id || topRated.id == nearest.id)
        ? null
        : topRated.id,
  );
});

final companyByIdProvider = Provider.family<Company?, String>((ref, id) {
  for (final company in ref.watch(companiesProvider)) {
    if (company.id == id) return company;
  }
  return null;
});
