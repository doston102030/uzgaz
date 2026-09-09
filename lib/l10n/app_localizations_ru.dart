// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Gaz & Energiya';

  @override
  String get home => 'Главная';

  @override
  String get catalog => 'Каталог';

  @override
  String get orders => 'Заказы';

  @override
  String get map => 'Карта';

  @override
  String get profile => 'Профиль';

  @override
  String get search => 'Поиск товара или компании';

  @override
  String get addToCart => 'В корзину';

  @override
  String get checkout => 'Оформить заказ';

  @override
  String get delivery => 'Доставка';

  @override
  String get selfPickup => 'Самовывоз';

  @override
  String get total => 'Итого';

  @override
  String get confirmOrder => 'Подтвердить заказ';

  @override
  String get orderPlaced => 'Заказ принят!';
}
