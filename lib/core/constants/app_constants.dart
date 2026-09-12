import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Gaz & Energiya';
  static const String tagline = 'Energiya — bir necha tegishda';
  static const String supportPhone = '+998 71 200 00 00';

  // Layout
  static const int companyComparisonMin = 5;
  static const int companyComparisonMax = 6;

  // Storage keys
  static const String keyOnboardingSeen = 'onboarding_seen';
  static const String keyAuthToken = 'auth_token';
  static const String keyLocale = 'app_locale';
  static const String keyThemeMode = 'theme_mode';
  static const String keySavedAddresses = 'saved_addresses';

  // Default map camera (Andijon shahri)
  static const double defaultLat = 40.7833;
  static const double defaultLng = 72.3444;

  /// Fallback delivery fee used by checkout when no company is selected.
  static const int defaultDeliveryFee = 15000;
}

/// Main service categories from the product spec.
enum ServiceCategory {
  gazBallon,
  suyultirilganGaz,
  metanGaz,
  propanGaz,
  elektrQuvvatlash,
  benzin,
  dizel,
  market,
}

extension ServiceCategoryX on ServiceCategory {
  String get titleUz => switch (this) {
        ServiceCategory.gazBallon => 'Gaz ballon',
        ServiceCategory.suyultirilganGaz => 'Suyultirilgan gaz',
        ServiceCategory.metanGaz => 'Metan gaz',
        ServiceCategory.propanGaz => 'Propan gaz',
        ServiceCategory.elektrQuvvatlash => 'Elektr quvvatlash',
        ServiceCategory.benzin => 'Benzin',
        ServiceCategory.dizel => 'Dizel',
        ServiceCategory.market => 'Market',
      };

  String get subtitleUz => switch (this) {
        ServiceCategory.gazBallon => '25L, 50L ballonlar',
        ServiceCategory.suyultirilganGaz => 'Aholi uchun subsidiya',
        ServiceCategory.metanGaz => 'Siqilgan gaz',
        ServiceCategory.propanGaz => 'Suyultirilgan gaz',
        ServiceCategory.elektrQuvvatlash => 'Tezkor quvvatlash',
        ServiceCategory.benzin => 'AI-92, AI-95, AI-98',
        ServiceCategory.dizel => 'Yevro-5 dizel',
        ServiceCategory.market => 'Yo‘l do‘konlari',
      };

  IconData get icon => switch (this) {
        ServiceCategory.gazBallon => Icons.propane_tank_rounded,
        ServiceCategory.suyultirilganGaz => Icons.local_fire_department_rounded,
        ServiceCategory.metanGaz => Icons.air_rounded,
        ServiceCategory.propanGaz => Icons.whatshot_rounded,
        ServiceCategory.elektrQuvvatlash => Icons.bolt_rounded,
        ServiceCategory.benzin => Icons.local_gas_station_rounded,
        ServiceCategory.dizel => Icons.local_shipping_rounded,
        ServiceCategory.market => Icons.storefront_rounded,
      };

  Color get color => switch (this) {
        ServiceCategory.gazBallon => AppColors.primary,
        // Aholi uchun subsidiya kampaniyasining "Aktiv" nishonidagi yashil
        // bilan bir xil — oq/ko'k/yashil brend palitrasiga mos.
        ServiceCategory.suyultirilganGaz => AppColors.energyGreen,
        ServiceCategory.metanGaz => AppColors.energyMint,
        ServiceCategory.propanGaz => AppColors.energyFlame,
        ServiceCategory.elektrQuvvatlash => AppColors.energyElectric,
        ServiceCategory.benzin => AppColors.energyAmber,
        ServiceCategory.dizel => AppColors.energySlate,
        ServiceCategory.market => AppColors.info,
      };

  /// Matches `Product.categoryId` in the mock data source.
  String get id => name;

  String get iconAsset => switch (this) {
        ServiceCategory.gazBallon => 'assets/icons/gas_cylinder.svg',
        ServiceCategory.suyultirilganGaz => 'assets/icons/liquid_gas.svg',
        ServiceCategory.metanGaz => 'assets/icons/methane.svg',
        ServiceCategory.propanGaz => 'assets/icons/propane.svg',
        ServiceCategory.elektrQuvvatlash => 'assets/icons/electric.svg',
        ServiceCategory.benzin => 'assets/icons/petrol.svg',
        ServiceCategory.dizel => 'assets/icons/diesel.svg',
        ServiceCategory.market => 'assets/icons/market.svg',
      };

  /// Real photo shown inside the category tile's circle (see
  /// [ServiceTile]) — a small, free-license photo hosted in the same
  /// Supabase Storage bucket the product catalogue images use (see
  /// `ASSETS_ATTRIBUTION.md`). `null` for categories without a curated
  /// photo yet — the tile falls back to [icon] + [color].
  String? get photoUrl => switch (this) {
        ServiceCategory.gazBallon => '$_categoryPhotoBase/gaz-ballon.jpg',
        ServiceCategory.suyultirilganGaz => '$_categoryPhotoBase/suyultirilgan-gaz.jpg',
        ServiceCategory.metanGaz => '$_categoryPhotoBase/metan-gaz.jpg',
        ServiceCategory.propanGaz => '$_categoryPhotoBase/propan-gaz.jpg',
        ServiceCategory.elektrQuvvatlash => '$_categoryPhotoBase/elektr-quvvatlash.jpg',
        ServiceCategory.benzin => '$_categoryPhotoBase/benzin.jpg',
        ServiceCategory.dizel || ServiceCategory.market => null,
      };
}

const String _categoryPhotoBase =
    'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/categories';

/// Andijon viloyati — xarita ekranidagi hudud filtri. Andijon shahri
/// (viloyat markazi) + 14 ta tuman, taxminiy markaziy koordinatalari bilan.
enum AndijonDistrict {
  andijonShahri,
  andijonTumani,
  asaka,
  baliqchi,
  boz,
  buloqboshi,
  izboskan,
  jalaquduq,
  marhamat,
  oltinkol,
  paxtaobod,
  qorgontepa,
  shahrixon,
  ulugnor,
  xojaobod,
}

extension AndijonDistrictX on AndijonDistrict {
  String get titleUz => switch (this) {
        AndijonDistrict.andijonShahri => 'Andijon shahri',
        AndijonDistrict.andijonTumani => 'Andijon tumani',
        AndijonDistrict.asaka => 'Asaka',
        AndijonDistrict.baliqchi => 'Baliqchi',
        AndijonDistrict.boz => 'Bo‘z',
        AndijonDistrict.buloqboshi => 'Buloqboshi',
        AndijonDistrict.izboskan => 'Izboskan',
        AndijonDistrict.jalaquduq => 'Jalaquduq',
        AndijonDistrict.marhamat => 'Marhamat',
        AndijonDistrict.oltinkol => 'Oltinko‘l',
        AndijonDistrict.paxtaobod => 'Paxtaobod',
        AndijonDistrict.qorgontepa => 'Qo‘rg‘ontepa',
        AndijonDistrict.shahrixon => 'Shahrixon',
        AndijonDistrict.ulugnor => 'Ulug‘nor',
        AndijonDistrict.xojaobod => 'Xo‘jaobod',
      };

  /// Approximate district-centre coordinates — good enough to re-centre
  /// the map's stylised canvas on a chip tap; not survey-grade GIS data.
  double get latitude => switch (this) {
        AndijonDistrict.andijonShahri => 40.7833,
        AndijonDistrict.andijonTumani => 40.8206,
        AndijonDistrict.asaka => 40.6414,
        AndijonDistrict.baliqchi => 40.6186,
        AndijonDistrict.boz => 40.8781,
        AndijonDistrict.buloqboshi => 40.7206,
        AndijonDistrict.izboskan => 40.8272,
        AndijonDistrict.jalaquduq => 40.9106,
        AndijonDistrict.marhamat => 40.4497,
        AndijonDistrict.oltinkol => 40.5433,
        AndijonDistrict.paxtaobod => 40.6069,
        AndijonDistrict.qorgontepa => 40.7156,
        AndijonDistrict.shahrixon => 40.7275,
        AndijonDistrict.ulugnor => 40.6394,
        AndijonDistrict.xojaobod => 40.8781,
      };

  double get longitude => switch (this) {
        AndijonDistrict.andijonShahri => 72.3444,
        AndijonDistrict.andijonTumani => 72.4206,
        AndijonDistrict.asaka => 72.2331,
        AndijonDistrict.baliqchi => 72.1622,
        AndijonDistrict.boz => 72.5417,
        AndijonDistrict.buloqboshi => 72.4500,
        AndijonDistrict.izboskan => 72.4728,
        AndijonDistrict.jalaquduq => 72.6494,
        AndijonDistrict.marhamat => 72.2739,
        AndijonDistrict.oltinkol => 72.1547,
        AndijonDistrict.paxtaobod => 72.2917,
        AndijonDistrict.qorgontepa => 72.0925,
        AndijonDistrict.shahrixon => 72.0281,
        AndijonDistrict.ulugnor => 72.6208,
        AndijonDistrict.xojaobod => 72.6494,
      };
}

enum OrderStatus { qabulQilindi, tayyorlanmoqda, yolda, yetkazildi }

extension OrderStatusX on OrderStatus {
  String get labelUz => switch (this) {
        OrderStatus.qabulQilindi => 'Qabul qilindi',
        OrderStatus.tayyorlanmoqda => 'Tayyorlanmoqda',
        OrderStatus.yolda => 'Yo‘lda',
        OrderStatus.yetkazildi => 'Yetkazildi',
      };

  int get step => OrderStatus.values.indexOf(this);

  bool get isActive => this != OrderStatus.yetkazildi;
}

enum DeliveryMethod { delivery, selfPickup }

extension DeliveryMethodX on DeliveryMethod {
  String get labelUz => switch (this) {
        DeliveryMethod.delivery => 'Yetkazib berish',
        DeliveryMethod.selfPickup => 'O‘zim borib olaman',
      };

  String get hintUz => switch (this) {
        DeliveryMethod.delivery => 'Kuryer manzilingizga olib keladi',
        DeliveryMethod.selfPickup => 'Firmadan o‘zingiz olib ketasiz — yetkazish bepul',
      };

  IconData get icon => switch (this) {
        DeliveryMethod.delivery => Icons.local_shipping_rounded,
        DeliveryMethod.selfPickup => Icons.storefront_rounded,
      };
}

/// Who is signed in — drives which shell (buyer / seller / admin) the
/// router shows after auth. One codebase, one build; the role decides
/// the flow.
enum UserRole { buyer, seller, admin }

extension UserRoleX on UserRole {
  String get labelUz => switch (this) {
        UserRole.buyer => 'Xaridor',
        UserRole.seller => 'Sotuvchi',
        UserRole.admin => 'Administrator',
      };
}

enum SellerStatus { pending, approved, rejected, suspended }

extension SellerStatusX on SellerStatus {
  String get labelUz => switch (this) {
        SellerStatus.pending => 'Ko‘rib chiqilmoqda',
        SellerStatus.approved => 'Tasdiqlangan',
        SellerStatus.rejected => 'Rad etilgan',
        SellerStatus.suspended => 'To‘xtatilgan',
      };
}

enum ProductModerationStatus { pending, approved, rejected }

extension ProductModerationStatusX on ProductModerationStatus {
  String get labelUz => switch (this) {
        ProductModerationStatus.pending => 'Moderatsiyada',
        ProductModerationStatus.approved => 'Faol',
        ProductModerationStatus.rejected => 'Rad etilgan',
      };
}

/// Seller-side order lifecycle — a superset the buyer-side [OrderStatus]
/// maps onto (see [SellerOrderStatusX.toOrderStatus]).
enum SellerOrderStatus { yangi, tayyorlanmoqda, yetkazishga, yopildi, bekorQilindi }

extension SellerOrderStatusX on SellerOrderStatus {
  String get labelUz => switch (this) {
        SellerOrderStatus.yangi => 'Yangi',
        SellerOrderStatus.tayyorlanmoqda => 'Tayyorlanmoqda',
        SellerOrderStatus.yetkazishga => 'Yetkazishga tayyor',
        SellerOrderStatus.yopildi => 'Yopildi',
        SellerOrderStatus.bekorQilindi => 'Bekor qilindi',
      };

  OrderStatus get toOrderStatus => switch (this) {
        SellerOrderStatus.yangi => OrderStatus.qabulQilindi,
        SellerOrderStatus.tayyorlanmoqda => OrderStatus.tayyorlanmoqda,
        SellerOrderStatus.yetkazishga => OrderStatus.yolda,
        SellerOrderStatus.yopildi => OrderStatus.yetkazildi,
        SellerOrderStatus.bekorQilindi => OrderStatus.yetkazildi,
      };
}

enum PaymentMethod { visa, mastercard, uzcard, humo, payme, click }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.visa => 'Visa',
        PaymentMethod.mastercard => 'Mastercard',
        PaymentMethod.uzcard => 'UZCARD',
        PaymentMethod.humo => 'HUMO',
        PaymentMethod.payme => 'Payme',
        PaymentMethod.click => 'Click',
      };

  String get hintUz => switch (this) {
        PaymentMethod.visa => 'Xalqaro karta',
        PaymentMethod.mastercard => 'Xalqaro karta',
        PaymentMethod.uzcard => 'Milliy to‘lov tizimi',
        PaymentMethod.humo => 'Milliy to‘lov tizimi',
        PaymentMethod.payme => 'Ilova orqali tasdiqlash',
        PaymentMethod.click => 'Ilova orqali tasdiqlash',
      };

  bool get isCard => switch (this) {
        PaymentMethod.visa ||
        PaymentMethod.mastercard ||
        PaymentMethod.uzcard ||
        PaymentMethod.humo =>
          true,
        _ => false,
      };
}
