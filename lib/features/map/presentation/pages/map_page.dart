import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/motion.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/map_company_card.dart';
import '../../../../core/widgets/pulsing_marker.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/company_provider.dart';

/// Map screen — a real OpenStreetMap map (via `flutter_map`), not a
/// stylised illustration. Chosen over the native Google/Yandex Maps SDKs
/// because it needs no API key and no native Android SDK plugin, which
/// sidesteps the compileSdk conflict that blocked the earlier Yandex Maps
/// attempt. Swapping in a paid tile provider (or the Yandex SDK, once that
/// conflict is resolved) later only means changing [_MapPageState]'s
/// `TileLayer`.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.78);
  late final AnimatedMapController _mapController;
  int _selected = 0;

  /// Which Andijon tuman the map is focused on.
  AndijonDistrict _district = AndijonDistrict.andijonShahri;

  /// Real device location, once [_useMyLocation] resolves one. Feeds the
  /// user marker on the map only after a real position is available.
  ({double lat, double lng})? _myLocation;
  bool _locatingMe = false;

  @override
  void initState() {
    super.initState();
    _mapController = AnimatedMapController(
      vsync: this,
      duration: AppMotion.slow,
      curve: AppMotion.standard,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _select(int index) {
    final companies = ref.read(sortedCompaniesProvider);
    if (index < 0 || index >= companies.length) return;
    setState(() => _selected = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: AppMotion.slow,
        curve: AppMotion.standard,
      );
    }
    _focusSelectedCompany();
  }

  void _focusSelectedCompany() {
    final companies = ref.read(sortedCompaniesProvider);
    if (_selected >= companies.length) return;
    final company = companies[_selected];
    _mapController.animateTo(
      dest: LatLng(company.latitude, company.longitude),
    );
  }

  void _focusDistrict(AndijonDistrict district) {
    setState(() => _district = district);
    _mapController.animateTo(
      dest: LatLng(district.latitude, district.longitude),
      zoom: 13,
    );
  }

  Future<void> _searchCompanies() async {
    final companies = ref.read(sortedCompaniesProvider);
    final index = await showSearch<int?>(
      context: context,
      delegate: _CompanySearchDelegate(companies),
    );
    if (mounted && index != null) _select(index);
  }

  Future<void> _useMyLocation() async {
    if (_locatingMe) return;
    setState(() => _locatingMe = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          AppToast.show(context, 'Joylashuv xizmati o‘chirilgan',
              icon: Icons.location_off_rounded);
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppToast.show(context, 'Joylashuvga ruxsat berilmadi',
              icon: Icons.location_off_rounded);
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() =>
          _myLocation = (lat: position.latitude, lng: position.longitude));
      _mapController.animateTo(
        dest: LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'Joylashuvni aniqlab bo‘lmadi',
            icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _locatingMe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final companies = ref.watch(sortedCompaniesProvider);
    final selectedIndex =
        companies.isEmpty ? 0 : _selected.clamp(0, companies.length - 1);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final userLatLng =
        _myLocation == null ? null : LatLng(_myLocation!.lat, _myLocation!.lng);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController.mapController,
              options: MapOptions(
                initialCenter: LatLng(_district.latitude, _district.longitude),
                initialZoom: 13,
                minZoom: 6,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gazenergiya.gaz_energiya',
                ),
                if (companies.isNotEmpty && userLatLng != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          userLatLng,
                          LatLng(
                            companies[selectedIndex].latitude,
                            companies[selectedIndex].longitude,
                          ),
                        ],
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: c.primary.withValues(alpha: 0.18),
                      ),
                      Polyline(
                        points: [
                          userLatLng,
                          LatLng(
                            companies[selectedIndex].latitude,
                            companies[selectedIndex].longitude,
                          ),
                        ],
                        strokeWidth: 3.5,
                        strokeCap: StrokeCap.round,
                        color: c.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (userLatLng != null)
                      Marker(
                        point: userLatLng,
                        width: 40,
                        height: 40,
                        child: PulsingMarker(
                          color: c.primary,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: c.primary.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    for (int i = 0; i < companies.length; i++)
                      Marker(
                        point: LatLng(
                            companies[i].latitude, companies[i].longitude),
                        width: 64,
                        height: 84,
                        alignment: Alignment.bottomCenter,
                        child: _MapMarker(
                          company: companies[i],
                          selected: i == selectedIndex,
                          onTap: () => _select(i),
                        ),
                      ),
                  ],
                ),
                Scalebar(
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.only(
                    left: AppDimensions.gutter,
                    bottom: 336 + bottomPad,
                  ),
                  lineColor: c.textSecondary,
                  textStyle: AppTypography.caption2.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomRight,
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top chrome: search + filter + district chips, floating on glass.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                0,
                topPad + AppDimensions.space8,
                0,
                AppDimensions.space12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.background.withValues(alpha: 0.96),
                    c.background.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.gutter),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            hint: 'Manzil yoki kompaniya qidirish',
                            readOnly: true,
                            onTap: _searchCompanies,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        AppIconButton(
                          icon: Icons.tune_rounded,
                          size: 48,
                          iconSize: 20,
                          onTap: () => context.push('/companies'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  SizedBox(
                    height: AppDimensions.chipHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.gutter),
                      itemCount: AndijonDistrict.values.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppDimensions.space8),
                      itemBuilder: (context, i) {
                        final district = AndijonDistrict.values[i];
                        return AppChip(
                          label: district.titleUz,
                          selected: district == _district,
                          onTap: () => _focusDistrict(district),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right-hand controls.
          Positioned(
            right: AppDimensions.gutter,
            bottom: 236 + MediaQuery.paddingOf(context).bottom,
            child: Column(
              children: [
                const _CompassBadge(),
                const SizedBox(height: AppDimensions.space10),
                AppIconButton(
                  icon: Icons.my_location_rounded,
                  size: 44,
                  foreground: c.primary,
                  onTap: _locatingMe
                      ? null
                      : () {
                          AppToast.show(context, 'Joylashuv aniqlanmoqda…',
                              icon: Icons.gps_fixed_rounded);
                          _useMyLocation();
                        },
                ),
              ],
            ),
          ),

          // Bottom: pickup hint + company carousel.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDimensions.bottomBarClearance - 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.gutter,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: AppPill(
                              label:
                                  'Yaqin atrofda ${companies.length} ta filial',
                              tone: PillTone.primary,
                              icon: Icons.place_rounded,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          const Spacer(),
                          AppTappable(
                            onTap: () => context.push('/companies'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: AppDimensions.brPill,
                                border: Border.all(color: c.border),
                                boxShadow: c.shadowSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.list_rounded,
                                      size: 14, color: c.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ro‘yxat',
                                    style: AppTypography.caption.copyWith(
                                      color: c.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space10),
                    SizedBox(
                      height: MapCompanyCard.slotHeightFor(context),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: companies.length,
                        padEnds: false,
                        onPageChanged: (i) {
                          setState(() => _selected = i);
                          _focusSelectedCompany();
                        },
                        itemBuilder: (context, i) {
                          final company = companies[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              left: i == 0
                                  ? AppDimensions.gutter
                                  : AppDimensions.space6,
                              right: AppDimensions.space6,
                              top: AppDimensions.space4,
                              bottom: AppDimensions.space8,
                            ),
                            child: MapCompanyCard(
                              company: company,
                              width: double.infinity,
                              selected: i == selectedIndex,
                              onTap: () => _select(i),
                              onSelect: () {
                                ref
                                    .read(selectedCompanyProvider.notifier)
                                    .state = company;
                                ref
                                    .read(deliveryMethodProvider.notifier)
                                    .state = DeliveryMethod.selfPickup;
                                context.push('/delivery-method',
                                    extra: company);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanySearchDelegate extends SearchDelegate<int?> {
  _CompanySearchDelegate(this.companies);

  final List<Company> companies;

  @override
  String get searchFieldLabel => 'Kompaniya yoki manzil qidirish';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'Tozalash',
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        tooltip: 'Orqaga',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final search = query.trim().toLowerCase();
    final matches = [
      for (var i = 0; i < companies.length; i++)
        if (search.isEmpty ||
            companies[i].name.toLowerCase().contains(search) ||
            companies[i].address.toLowerCase().contains(search))
          i,
    ];
    if (matches.isEmpty) {
      return const Center(child: Text('Hech narsa topilmadi'));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final companyIndex = matches[index];
        final company = companies[companyIndex];
        return ListTile(
          leading: const Icon(Icons.place_rounded),
          title: Text(company.name),
          subtitle: company.address.isEmpty ? null : Text(company.address),
          onTap: () => close(context, companyIndex),
        );
      },
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.company,
    required this.selected,
    required this.onTap,
  });

  final Company company;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = company.isAvailable ? c.primary : c.textTertiary;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AppTappable(
        onTap: onTap,
        pressedScale: 0.9,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.spring,
          width: selected ? 60 : 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: AppDimensions.brPill,
                    boxShadow: c.shadowSm,
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    '${(company.productPrice / 1000).round()}k',
                    style: AppTypography.caption2.copyWith(
                      color: c.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                ),
              Container(
                width: selected ? 44 : 36,
                height: selected ? 44 : 36,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: tone.withValues(alpha: 0.4),
                      blurRadius: selected ? 18 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: selected ? 21 : 17,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -3),
                child: CustomPaint(
                  size: const Size(12, 8),
                  painter: _PinTailPainter(tone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}

/// Floating "N" badge. Purely decorative — safe to show as always
/// north-up since [InteractiveFlag.rotate] is disabled on the map, so the
/// camera bearing never actually changes.
class _CompassBadge extends StatelessWidget {
  const _CompassBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: c.border),
        boxShadow: c.shadowSm,
      ),
      child: CustomPaint(
        painter: _CompassNeedlePainter(north: c.danger, south: c.textTertiary),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  _CompassNeedlePainter({required this.north, required this.south});

  final Color north;
  final Color south;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width * 0.3;

    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.42, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.42, center.dy)
      ..close();

    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r * 0.42, center.dy)
        ..lineTo(center.dx, center.dy)
        ..close(),
      Paint()..color = north,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * 0.42, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r * 0.42, center.dy)
        ..close(),
      Paint()..color = south,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter old) => false;
}
