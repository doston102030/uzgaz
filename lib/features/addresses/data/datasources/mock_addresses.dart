import '../../domain/entities/address.dart';

final List<Address> mockAddresses = [
  const Address(
    id: 'a1',
    title: 'Uy',
    fullAddress: 'Andijon, Shahrixon ko\u2018chasi, Mustaqillik ko\u2018chasi 25',
    latitude: 40.7833,
    longitude: 72.3444,
    apartment: '13',
    isDefault: true,
  ),
  const Address(
    id: 'a2',
    title: 'Ish',
    fullAddress: 'Toshkent, Yunusobod tumani, Amir Temur shoh ko\u2018chasi 108',
    latitude: 41.3406,
    longitude: 69.2879,
  ),
];
