class ClientProfile {
  final String clientId;
  final String name;
  final String phone;
  final String language;
  final String? address;
  final int updatedAt;

  ClientProfile({
    required this.clientId,
    required this.name,
    required this.phone,
    required this.language,
    this.address,
    required this.updatedAt
  });

  Map<String, Object?> toMap() => {
    'client_id': clientId,
    'name': name,
    'phone': phone,
    'language': language,
    'address': address,
    'updated_at': updatedAt,
  };

  static ClientProfile fromMap(Map<String, Object?> m) => ClientProfile(
    clientId: m['client_id'] as String,
    name: m['name'] as String,
    phone: m['phone'] as String,
    language: m['language'] as String,
    address: m['address'] as String?,
    updatedAt: m['updated_at'] as int,
  );
}
