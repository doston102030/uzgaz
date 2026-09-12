import '../../domain/entities/address.dart';

final List<Address> mockAddresses = [
  const Address(
    id: 'a1',
    title: 'Uy',
    fullAddress: 'Andijon, Bog\u2018ishamol ko\u2018chasi 12',
    latitude: 40.7833,
    longitude: 72.3444,
    apartment: '13',
    isDefault: true,
  ),
  const Address(
    id: 'a2',
    title: 'Ish',
    fullAddress: 'Asaka tumani, Mustaqillik ko\u2018chasi 7',
    latitude: 40.6414,
    longitude: 72.2331,
  ),
];
